# http://localhost:8000

import sys
import os
import logging

# Enable Azure AI content tracing for Foundry observability
# This MUST be set before importing Azure AI SDKs
os.environ.setdefault("AZURE_TRACING_GEN_AI_CONTENT_RECORDING_ENABLED", "true")

# Configure Azure Monitor OpenTelemetry BEFORE other imports
# This ensures all instrumentation is properly initialized
APPLICATIONINSIGHTS_CONNECTION_STRING = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING", "")
if APPLICATIONINSIGHTS_CONNECTION_STRING:
    from azure.monitor.opentelemetry import configure_azure_monitor
    from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
    
    # Configure Azure Monitor with AI inference tracing
    configure_azure_monitor(
        connection_string=APPLICATIONINSIGHTS_CONNECTION_STRING,
        enable_live_metrics=True,
        logger_name="cora-web-app",
        instrumentation_options={
            "azure_sdk": {"enabled": True},  # Enable Azure SDK tracing
        }
    )
    
    # Instrument httpx for outbound AI API calls
    HTTPXClientInstrumentor().instrument()
    
    logging.getLogger(__name__).info("Azure Monitor OpenTelemetry configured with AI tracing for Foundry observability")

from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect, UploadFile, File
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import uvicorn
import json
import asyncio
from typing import List, Dict, Optional
import base64
from contextlib import AsyncExitStack
import uuid
from pathlib import Path

# Resolve shared asset paths relative to this file (web_app.py)
BASE_SRC_DIR = Path(__file__).resolve().parents[2]  # -> /workspace/src
SHARED_STATIC_DIR = BASE_SRC_DIR / "shared" / "static"

# Use shared/static when present; fall back to project-root static/templates
STATIC_DIR = SHARED_STATIC_DIR if SHARED_STATIC_DIR.exists() else Path("static")
TEMPLATES_DIR = STATIC_DIR if STATIC_DIR.exists() else Path("templates")

# Agent Framework imports
from agent_framework import ChatAgent, MCPStdioTool, ToolProtocol, ChatMessage, TextContent, DataContent
from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential, ManagedIdentityCredential
from azure.core.credentials import AccessToken
import time


class StaticTokenCredential:
    """Credential that uses a pre-fetched access token."""
    
    def __init__(self, token: str, expires_on: int):
        self._token = token
        self._expires_on = expires_on
    
    async def get_token(self, *scopes: str, **kwargs) -> AccessToken:
        return AccessToken(self._token, self._expires_on)
    
    async def close(self) -> None:
        pass
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, *args):
        pass


from dotenv import load_dotenv

load_dotenv()  # Loads variables from .env into os.environ

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create uploads directory if it doesn't exist
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

def encodeImage(path, mime_type):
    """Encode image file to base64 for use with AI models"""
    with open(path, "rb") as image:
        encoded = base64.b64encode(image.read())
    return f"data:{mime_type};base64,{encoded.decode()}"

def get_image_mime_type(filename: str) -> str:
    """Get MIME type based on file extension"""
    extension = filename.lower().split('.')[-1]
    mime_types = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp',
        'bmp': 'image/bmp'
    }
    return mime_types.get(extension, 'image/jpeg')

# Agent Framework Configuration - matching cora-agent-demo.py
ENDPOINT = os.environ.get("PROJECT_ENDPOINT", os.environ.get("AZURE_AI_FOUNDRY_ENDPOINT", "your_foundry_endpoint_here"))
MODEL_DEPLOYMENT_NAME = os.environ.get("GPT_MODEL_DEPLOYMENT_NAME", os.environ.get("MODEL_DEPLOYMENT_NAME", "gpt-4o-mini"))
# API Key for authentication (get from Azure AI Foundry portal -> Keys)
API_KEY = os.environ.get("AZURE_AI_API_KEY", os.environ.get("AZURE_OPENAI_API_KEY", ""))
# Pre-fetched access token (optional - for Docker environments)
ACCESS_TOKEN = os.environ.get("AZURE_ACCESS_TOKEN", "")
# Managed Identity Client ID (for Azure Container Apps)
MANAGED_IDENTITY_CLIENT_ID = os.environ.get("AZURE_CLIENT_ID", "")
AGENT_NAME = "cora-web-agent"

# Workspace root for absolute paths (ensures MCP server works regardless of cwd)
WORKSPACE_ROOT = Path(__file__).resolve().parents[3]  # -> /workspace

def create_mcp_tools() -> list[ToolProtocol]:
    """Create MCP tools for the agent"""
    # Pass environment variables to MCP subprocess
    # This is required because subprocess doesn't always inherit parent env
    mcp_env = {
        "POSTGRES_URL": os.environ.get("POSTGRES_URL", ""),
        "PYTHONPATH": os.environ.get("PYTHONPATH", "/workspace/src/python"),
    }
    return [
        MCPStdioTool(
            name="zava_customer_sales_stdio",
            description="MCP server for Zava customer sales analysis",
            command=sys.executable,
            args=[
                str(WORKSPACE_ROOT / "src/python/mcp_server/customer_sales/customer_sales.py"),
                "--stdio",
                "--RLS_USER_ID=00000000-0000-0000-0000-000000000000",
            ],
            env=mcp_env,
        ),
    ]

app = FastAPI(title="AI Agent Chat Demo", version="1.0.0")

# Mount static files and templates
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))

# Global agent instance and thread storage
agent_instance = None
credential_instance = None
agent_threads = {}  # Store threads per session

# Agent instructions for Cora AI assistant
AGENT_INSTRUCTIONS = """You are Cora, an intelligent and friendly AI assistant for Zava, a home improvement brand. You help customers with their DIY projects by understanding their needs and recommending the most suitable products from Zava's catalog.

Your role is to:
- Engage with the customer in natural conversation to understand their DIY goals.
- Ask thoughtful questions to gather relevant project details.
- Be brief in your responses.
- Provide the best solution for the customer's problem and only recommend relevant products within Zava's product catalog.
- Search Zava's product database to identify ALL matching products (up to 5) that match the customer's needs.
- Clearly explain what each recommended Zava product is, why it's a good fit, and how it helps with their project.
- When users provide images, analyze them carefully to understand what they show and how it relates to their DIY project.

Your personality is:
- Warm and welcoming, like a helpful store associate
- Professional and knowledgeable, like a seasoned DIY expert
- Curious and conversational—never assume, always clarify
- Transparent and honest—if something isn't available, offer support anyway

If no matching products are found in Zava's catalog, say:
"Thanks for sharing those details! I've searched our catalog, but it looks like we don't currently have a product that fits your exact needs. If you'd like, I can suggest some alternatives or help you adjust your project requirements to see if something similar might work."
"""

async def initialize_agent():
    """Initialize the Agent Framework agent using AzureAIClient"""
    global agent_instance, credential_instance
    if agent_instance is None:
        try:
            # Authentication priority:
            # 1. Pre-fetched access token (for local Docker)
            # 2. Managed Identity (for Azure Container Apps)
            # 3. DefaultAzureCredential (fallback)
            if ACCESS_TOKEN:
                logger.info("Using pre-fetched access token for authentication")
                # Token expires in ~1 hour, set to 55 min from now
                credential_instance = StaticTokenCredential(ACCESS_TOKEN, int(time.time()) + 3300)
            elif MANAGED_IDENTITY_CLIENT_ID:
                logger.info(f"Using Managed Identity for authentication (client_id: {MANAGED_IDENTITY_CLIENT_ID[:8]}...)")
                credential_instance = ManagedIdentityCredential(client_id=MANAGED_IDENTITY_CLIENT_ID)
            else:
                # Fall back to DefaultAzureCredential (works with managed identity, env vars, etc.)
                logger.info("Using DefaultAzureCredential for authentication")
                credential_instance = DefaultAzureCredential()
            
            # Create AzureAIClient for Foundry project endpoint
            client = AzureAIClient(
                project_endpoint=ENDPOINT,
                model_deployment_name=MODEL_DEPLOYMENT_NAME,
                credential=credential_instance,
                agent_name=AGENT_NAME,
            )
            
            # Create agent with the Azure AI client
            agent_instance = client.create_agent(
                name=AGENT_NAME,
                instructions=AGENT_INSTRUCTIONS,
                tools=[
                    *create_mcp_tools(),
                ],
            )
            logger.info("Agent Framework initialized successfully with AzureAIClient")
        except Exception as e:
            logger.error(f"Failed to initialize Agent Framework: {e}")
            import traceback
            traceback.print_exc()
            agent_instance = None

# Store active connections
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

manager = ConnectionManager()

@app.post("/upload-image")
async def upload_image(file: UploadFile = File(...)):
    """Handle image upload"""
    try:
        # Validate file type
        if not file.content_type or not file.content_type.startswith('image/'):
            return {"error": "Please upload a valid image file"}
        
        # Generate unique filename
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = UPLOAD_DIR / unique_filename
        
        # Save file
        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)
        
        # Return file URL
        file_url = f"/uploads/{unique_filename}"
        
        logger.info(f"Image uploaded: {file_url}")
        return {"success": True, "file_url": file_url, "filename": unique_filename}
        
    except Exception as e:
        logger.error(f"Error uploading image: {e}")
        return {"error": f"Upload failed: {str(e)}"}

@app.get("/", response_class=HTMLResponse)
async def get_chat_page(request: Request):
    """Serve the main chat interface"""
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "AI Agent Chat Demo"}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time chat"""
    await manager.connect(websocket)
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            message_data = json.loads(data)
            user_message = message_data.get("message", "")
            image_url = message_data.get("image_url")  # Optional image URL
            
            logger.info(f"Received message: {user_message}")
            if image_url:
                logger.info(f"With image: {image_url}")
            
            # Process message with AI agent
            ai_response = await simulate_ai_agent(user_message, image_url)
            
            # Send response back to client
            response_data = {
                "type": "ai_response",
                "message": ai_response,
                "timestamp": asyncio.get_event_loop().time()
            }
            
            await manager.send_personal_message(json.dumps(response_data), websocket)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info("Client disconnected")

async def simulate_ai_agent(user_message: str, image_url: Optional[str] = None, session_id: str = "default") -> str:
    """
    Process user message using Cora AI agent with Agent Framework
    """
    global agent_instance, agent_threads
    
    # Initialize agent if not already done
    if agent_instance is None:
        await initialize_agent()
    
    # If agent is still None, fall back to simple responses
    if agent_instance is None:
        return "I'm sorry, I'm having trouble connecting to my tools right now. Please try again later."
    
    try:
        # Get or create thread for this session
        if session_id not in agent_threads:
            agent_threads[session_id] = agent_instance.get_new_thread()
        
        thread = agent_threads[session_id]
        
        # Prepare message with image if provided
        if image_url:
            logger.info(f"Processing message with image: {image_url}")
            
            # Convert relative URL to file path
            if image_url.startswith("/uploads/"):
                filename = image_url.replace("/uploads/", "")
                file_path = UPLOAD_DIR / filename
                
                if file_path.exists():
                    # Get MIME type and read image as bytes
                    mime_type = get_image_mime_type(filename)
                    
                    # Read image file as raw bytes
                    with open(file_path, "rb") as image_file:
                        image_bytes = image_file.read()
                    
                    logger.info(f"Image loaded: {len(image_bytes)} bytes, MIME type: {mime_type}")
                    
                    # Create a ChatMessage with multimodal content using DataContent
                    # Note: use 'contents' (plural) not 'content'
                    message_with_image = [
                        ChatMessage(
                            role="user",
                            contents=[
                                TextContent(text=user_message),
                                DataContent(data=image_bytes, media_type=mime_type)
                            ]
                        )
                    ]
                    
                    logger.info(f"Sending message with image to agent: {user_message}")
                    
                    # Stream response from agent with image
                    response_text = ""
                    async for chunk in agent_instance.run_stream(message_with_image, thread=thread):
                        if chunk.text:
                            response_text += chunk.text
                else:
                    logger.warning(f"Image file not found: {file_path}")
                    # Fall back to text-only processing
                    response_text = ""
                    async for chunk in agent_instance.run_stream(user_message, thread=thread):
                        if chunk.text:
                            response_text += chunk.text
            else:
                logger.warning(f"Invalid image URL format: {image_url}")
                # Fall back to text-only processing
                response_text = ""
                async for chunk in agent_instance.run_stream(user_message, thread=thread):
                    if chunk.text:
                        response_text += chunk.text
        else:
            # Stream response from agent (text only)
            response_text = ""
            async for chunk in agent_instance.run_stream(user_message, thread=thread):
                if chunk.text:
                    response_text += chunk.text
        
        return response_text if response_text else "I processed your request, but I'm having trouble generating a response. Please try rephrasing your question."
            
    except Exception as e:
        logger.error(f"Error in AI agent processing: {e}")
        import traceback
        traceback.print_exc()
        return f"I encountered an error while processing your request: {str(e)}. Please try again."

@app.on_event("startup")
async def startup_event():
    """Initialize resources on startup"""
    await initialize_agent()

@app.on_event("shutdown")
async def shutdown_event():
    """Clean up resources on shutdown"""
    global agent_instance, credential_instance
    if agent_instance:
        try:
            # Agent cleanup if needed
            pass
        except Exception as e:
            logger.error(f"Error during agent cleanup: {e}")
        agent_instance = None
    
    # AzureKeyCredential doesn't need async cleanup
    credential_instance = None

if __name__ == "__main__":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )
