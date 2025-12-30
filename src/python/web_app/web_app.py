# http://localhost:8000

from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect, UploadFile, File
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import uvicorn
import json
import asyncio
from typing import List, Dict, Optional
import logging
import base64
import os
import uuid
from pathlib import Path

# Resolve shared asset paths relative to this file (web_app.py)
BASE_SRC_DIR = Path(__file__).resolve().parents[2]  # -> /workspace/src
SHARED_STATIC_DIR = BASE_SRC_DIR / "shared" / "static"

# Use shared/static when present; fall back to project-root static/templates
STATIC_DIR = SHARED_STATIC_DIR if SHARED_STATIC_DIR.exists() else Path("static")
TEMPLATES_DIR = STATIC_DIR if STATIC_DIR.exists() else Path("templates")

# OpenAI imports for API key auth
from openai import AsyncAzureOpenAI

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

# Azure OpenAI Configuration with API Key - Set these via environment variables
AZURE_OPENAI_ENDPOINT = os.environ.get("AZURE_OPENAI_ENDPOINT", "")
AZURE_OPENAI_API_KEY = os.environ.get("AZURE_OPENAI_API_KEY", "")
MODEL_DEPLOYMENT_NAME = os.environ.get("MODEL_DEPLOYMENT_NAME", "gpt-4o-mini")

app = FastAPI(title="AI Agent Chat Demo", version="1.0.0")

# Mount static files and templates
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))

# Global client and conversation storage
openai_client = None
conversations = {}  # Store conversation history per session

# Agent instructions for Cora AI assistant
SYSTEM_PROMPT = """You are Cora, an intelligent and friendly AI assistant for Zava, a home improvement brand. You help customers with their DIY projects by understanding their needs and recommending the most suitable products from Zava's catalog.

Your role is to:
- Engage with the customer in natural conversation to understand their DIY goals.
- Ask thoughtful questions to gather relevant project details.
- Be brief in your responses.
- Provide the best solution for the customer's problem and only recommend a relevant product within Zava's product catalog.
- Search Zava's product database to identify 5 products that best match the customer's needs.
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

async def initialize_client():
    """Initialize the Azure OpenAI client with API key"""
    global openai_client
    if openai_client is None:
        try:
            openai_client = AsyncAzureOpenAI(
                api_key=AZURE_OPENAI_API_KEY,
                api_version="2024-10-21",
                azure_endpoint=AZURE_OPENAI_ENDPOINT
            )
            logger.info(f"OpenAI client initialized with API key for endpoint: {AZURE_OPENAI_ENDPOINT}")
        except Exception as e:
            logger.error(f"Failed to initialize OpenAI client: {e}")
            import traceback
            traceback.print_exc()
            openai_client = None

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
    session_id = str(uuid.uuid4())
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
            
            # Process message with AI
            ai_response = await process_chat(user_message, image_url, session_id)
            
            # Send response back to client
            response_data = {
                "type": "ai_response",
                "message": ai_response,
                "timestamp": asyncio.get_event_loop().time()
            }
            
            await manager.send_personal_message(json.dumps(response_data), websocket)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        # Clean up conversation history
        if session_id in conversations:
            del conversations[session_id]
        logger.info("Client disconnected")

async def process_chat(user_message: str, image_url: Optional[str] = None, session_id: str = "default") -> str:
    """
    Process user message using Azure OpenAI with API key
    """
    global openai_client, conversations
    
    # Initialize client if not already done
    if openai_client is None:
        await initialize_client()
    
    if openai_client is None:
        return "I'm sorry, I'm having trouble connecting right now. Please try again later."
    
    try:
        # Get or create conversation history for this session
        if session_id not in conversations:
            conversations[session_id] = [
                {"role": "system", "content": SYSTEM_PROMPT}
            ]
        
        # Build the user message content
        if image_url and image_url.startswith("/uploads/"):
            filename = image_url.replace("/uploads/", "")
            file_path = UPLOAD_DIR / filename
            
            if file_path.exists():
                mime_type = get_image_mime_type(filename)
                base64_image = encodeImage(file_path, mime_type)
                
                logger.info(f"Processing image: {filename}")
                
                # Create message with image - use low detail to reduce tokens
                user_content = [
                    {"type": "text", "text": user_message},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": base64_image,
                            "detail": "low"  # Reduces token usage significantly
                        }
                    }
                ]
                
                # For image messages, create a temporary messages list
                # Don't store the full base64 in history to save memory
                temp_messages = conversations[session_id].copy()
                temp_messages.append({"role": "user", "content": user_content})
                
                # Call API with image
                response = await openai_client.chat.completions.create(
                    model=MODEL_DEPLOYMENT_NAME,
                    messages=temp_messages,
                    max_tokens=800
                )
                
                # Store only text reference in history
                conversations[session_id].append({
                    "role": "user", 
                    "content": f"{user_message} [Image attached]"
                })
            else:
                logger.warning(f"Image file not found: {file_path}")
                conversations[session_id].append({"role": "user", "content": user_message})
                response = await openai_client.chat.completions.create(
                    model=MODEL_DEPLOYMENT_NAME,
                    messages=conversations[session_id],
                    max_tokens=1000
                )
        else:
            # Text-only message
            conversations[session_id].append({"role": "user", "content": user_message})
            response = await openai_client.chat.completions.create(
                model=MODEL_DEPLOYMENT_NAME,
                messages=conversations[session_id],
                max_tokens=1000
            )
        
        # Extract response
        assistant_message = response.choices[0].message.content
        
        # Add assistant response to history
        conversations[session_id].append({"role": "assistant", "content": assistant_message})
        
        # Keep conversation history manageable (last 20 messages + system)
        if len(conversations[session_id]) > 21:
            conversations[session_id] = [conversations[session_id][0]] + conversations[session_id][-20:]
        
        return assistant_message if assistant_message else "I processed your request but couldn't generate a response."
            
    except Exception as e:
        logger.error(f"Error in chat processing: {e}")
        import traceback
        traceback.print_exc()
        return f"I encountered an error: {str(e)}. Please try again."

@app.on_event("startup")
async def startup_event():
    """Initialize resources on startup"""
    await initialize_client()

@app.on_event("shutdown")
async def shutdown_event():
    """Clean up resources on shutdown"""
    global openai_client
    if openai_client:
        await openai_client.close()
        openai_client = None

if __name__ == "__main__":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )
