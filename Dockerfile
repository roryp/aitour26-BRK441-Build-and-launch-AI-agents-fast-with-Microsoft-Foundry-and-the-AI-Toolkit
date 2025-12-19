# ===================================================================
# Cora AI Agent - Web Application Dockerfile
# ===================================================================
# Multi-stage build for the Zava Retail AI Assistant (Cora)
# This image runs the FastAPI web app with MCP tools for product search
# ===================================================================

FROM python:3.12-slim AS base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/workspace/src/python \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directory
WORKDIR /workspace

# ===================================================================
# Dependencies Stage - Install Python packages
# ===================================================================
FROM base AS dependencies

# Copy requirements first for better caching
COPY src/python/requirements.txt /workspace/src/python/requirements.txt

# Install Azure CLI FIRST (before other Azure packages to avoid conflicts)
RUN pip install --no-cache-dir azure-cli

# Install Python dependencies (may upgrade some Azure SDK packages)
RUN pip install --no-cache-dir -r /workspace/src/python/requirements.txt

# Install agent-framework for Azure AI integration (pre-release) - MUST be last
# This ensures the correct azure-ai-projects version is installed
RUN pip install --no-cache-dir --upgrade agent-framework-azure-ai --pre

# ===================================================================
# Application Stage - Copy source code
# ===================================================================
FROM dependencies AS application

# Copy the entire source tree
COPY src/ /workspace/src/

# Copy uploads directory (create if not exists)
RUN mkdir -p /workspace/uploads

# Create a non-root user for security
RUN useradd --create-home --shell /bin/bash appuser \
    && chown -R appuser:appuser /workspace

# ===================================================================
# Runtime Stage - Production image
# ===================================================================
FROM application AS runtime

# Switch to non-root user
USER appuser

# Set working directory to web_app
WORKDIR /workspace/src/python/web_app

# Expose the FastAPI port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the FastAPI web application
CMD ["python", "web_app.py"]
