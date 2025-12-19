# Docker Deployment Guide - Cora AI Agent

This guide explains how to run the complete Zava Retail AI Assistant (Cora) stack using Docker.

## Architecture

The Docker stack includes:

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Network                          │
│                    (zava-network)                           │
│                                                             │
│  ┌──────────────────┐         ┌──────────────────────────┐ │
│  │   PostgreSQL     │         │     Web App (Cora)       │ │
│  │   + pgvector     │◄────────│     FastAPI + MCP        │ │
│  │                  │         │                          │ │
│  │  Port: 15432     │         │     Port: 8000           │ │
│  │  (external)      │         │     (external)           │ │
│  │                  │         │                          │ │
│  │  Data: Zava      │         │  Azure AI Foundry        │ │
│  │  Retail DB       │         │  Integration             │ │
│  └──────────────────┘         └──────────────────────────┘ │
│                                         │                   │
└─────────────────────────────────────────│───────────────────┘
                                          │
                                          ▼
                               ┌──────────────────────┐
                               │  Azure AI Foundry    │
                               │  (GPT-4o-mini)       │
                               └──────────────────────┘
```

## Prerequisites

1. **Docker Desktop** installed and running
2. **Azure CLI** logged in (`az login`)
3. **Azure AI Foundry** project with deployed models:
   - GPT model (e.g., `gpt-4o-mini`)
   - Embedding model (e.g., `text-embedding-3-small`)

## Quick Start

### 1. Configure Environment

Copy your existing `.env` file settings or create from template:

```bash
# Copy the Docker template
cp .env.docker .env

# Edit with your Azure AI Foundry values
# Get PROJECT_ENDPOINT from: Azure AI Foundry Portal -> Your Project -> Settings
```

Your `.env` file should contain:
```
PROJECT_ENDPOINT=https://foundry-xxxx.services.ai.azure.com/api/projects/project-xxxx
GPT_MODEL_DEPLOYMENT_NAME=gpt-4o-mini
EMBEDDING_MODEL_DEPLOYMENT_NAME=text-embedding-3-small
```

### 2. Azure Login

The Docker container needs Azure credentials to authenticate with AI Foundry:

```bash
# Login to Azure (if not already)
az login

# Verify you're logged in
az account show
```

### 3. Build and Run

```bash
# Build and start all services
docker compose -f docker-compose.full.yml up --build

# Or run in detached mode
docker compose -f docker-compose.full.yml up --build -d
```

### 4. Wait for Initialization

The database initialization takes 2-3 minutes on first run:
- Creates `zava` database
- Installs `pgvector` extension
- Restores retail data backup
- Sets up Row Level Security

Watch the logs:
```bash
docker compose -f docker-compose.full.yml logs -f db
```

### 5. Access the Application

Once healthy, open your browser:
- **Web App**: http://localhost:8000
- **Database** (if needed): `localhost:15432` (user: `store_manager`, password: `StoreManager123!`)

## Services

| Service | Container Name | Port | Description |
|---------|---------------|------|-------------|
| db | zava-postgres | 15432 | PostgreSQL + pgvector with Zava retail data |
| web-app | zava-web-app | 8000 | Cora AI Assistant (FastAPI) |

## Useful Commands

```bash
# View logs
docker compose -f docker-compose.full.yml logs -f

# View specific service logs
docker compose -f docker-compose.full.yml logs -f web-app

# Stop services
docker compose -f docker-compose.full.yml down

# Stop and remove volumes (clean start)
docker compose -f docker-compose.full.yml down -v

# Rebuild a specific service
docker compose -f docker-compose.full.yml build web-app

# Shell into a container
docker exec -it zava-web-app /bin/bash
docker exec -it zava-postgres psql -U postgres -d zava
```

## Troubleshooting

### Database Not Ready

If web-app fails to start, the database may still be initializing:
```bash
# Check db logs
docker compose -f docker-compose.full.yml logs db

# Wait for "Zava PostgreSQL Database initialization completed!"
```

### Azure Authentication Issues

If you see "Failed to initialize Agent Framework" errors:

1. Ensure you're logged in: `az login`
2. Check Azure CLI config is mounted correctly
3. Verify the PROJECT_ENDPOINT is correct

### Port Conflicts

If ports 8000 or 15432 are in use:
```bash
# Edit docker-compose.full.yml to use different ports
# e.g., "8080:8000" instead of "8000:8000"
```

### Clean Restart

For a completely fresh start:
```bash
docker compose -f docker-compose.full.yml down -v
docker compose -f docker-compose.full.yml up --build
```

## Production Deployment (Azure Container Apps)

For Azure Container Apps deployment, you'll need:

1. **Azure Container Registry** to push images
2. **Managed Identity** for authentication (instead of Azure CLI)
3. **Azure Database for PostgreSQL** (instead of container)

See the `infra/` folder for Bicep templates.

### Build for Container Registry

```bash
# Login to ACR
az acr login --name <your-acr-name>

# Build and push
docker build -t <your-acr-name>.azurecr.io/zava-web-app:latest .
docker push <your-acr-name>.azurecr.io/zava-web-app:latest
```

## Development Mode

For local development with hot-reload:

```bash
# Start just the database
docker compose -f docker-compose.full.yml up db

# Run the web app locally (outside Docker)
cd src/python/web_app
pip install -r ../requirements.txt agent-framework-azure-ai --pre
python web_app.py
```

## Files Reference

| File | Description |
|------|-------------|
| `Dockerfile` | Main web application image |
| `Dockerfile.mcp` | MCP server image (for HTTP mode) |
| `docker-compose.yml` | Database only (original) |
| `docker-compose.full.yml` | Full stack (DB + Web App) |
| `.env.docker` | Environment template |
| `scripts/init-db.sh` | Database initialization script |
