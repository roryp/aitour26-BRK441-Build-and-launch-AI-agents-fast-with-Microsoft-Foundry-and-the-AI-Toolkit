<p align="center">
<img src="img/Banner-MS-AI-Tour-26.png" alt="decorative banner" width="1200"/>
</p>

# [Microsoft AI Tour 2026](https://aitour.microsoft.com)

## 🔥BRK441: Build and launch AI agents fast with Microsoft Foundry and the AI Toolkit

[![Microsoft Foundry Discord](https://dcbadge.limes.pink/api/server/Pwpvf3TWaw)](https://aka.ms/MicrosoftFoundryDiscord-AITour26)
[![Microsoft Foundry Developer Forum](https://img.shields.io/badge/GitHub-Microsoft_Foundry_Developer_Forum-blue?style=for-the-badge&logo=github&color=adff2f&logoColor=fff)](https://aka.ms/MicrosoftFoundryForum-AITour26)

If you will be delivering this session, check the [session-delivery-sources](./session-delivery-resources/) folder for slides, scripts, and other resources.

### Session Description

Build and ship AI agents fast with Microsoft Foundry Models and Azure. Prototype with open models, scale with Foundry models, and streamline workflows using the AI Toolkit in VS Code. Experiment with models and prompts, evaluate agent responses, then move from prototype to cloud with cutting-edge developer tools.

---

## 📖 Application Overview

### What is Cora?

**Cora** is an AI-powered shopping assistant for Zava, a home improvement retail brand. Cora enables customers to interact with a conversational AI that understands natural language queries about DIY projects and provides intelligent product recommendations from the store's inventory.

#### Key Capabilities

- **Natural Language Understanding**: Customers can ask questions like "What drill should I buy for hanging shelves?" and receive contextual recommendations
- **Product Search & Discovery**: AI-powered search across the complete product catalog with semantic understanding
- **Personalized Recommendations**: Suggestions tailored to the customer's project requirements and preferences
- **Real-time Inventory Access**: Direct integration with the product database for accurate, up-to-date information

### Technical Architecture

The application follows a modern AI agent architecture with three primary layers:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           User Interface                                │
│                     (FastAPI Web Application)                           │
└─────────────────────────────────────┬───────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           AI Agent Layer                                │
│                                                                         │
│  ┌─────────────────┐         ┌─────────────────┐                       │
│  │   GPT-4o-mini   │◄───────►│   MCP Client    │                       │
│  │   (Reasoning)   │         │   (Tool Calls)  │                       │
│  └─────────────────┘         └────────┬────────┘                       │
│                                       │                                 │
└───────────────────────────────────────┼─────────────────────────────────┘
                                        │ MCP Protocol
                                        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           Data Layer                                    │
│                                                                         │
│  ┌─────────────────┐         ┌─────────────────┐                       │
│  │   MCP Server    │────────►│   PostgreSQL    │                       │
│  │ (Tool Provider) │         │   (pgvector)    │                       │
│  └─────────────────┘         └─────────────────┘                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Model Context Protocol (MCP)

The application leverages **Model Context Protocol (MCP)** to enable secure, structured communication between the AI model and external data sources.

#### What is MCP?

MCP is an open protocol that standardizes how AI models interact with tools and data sources. Rather than allowing arbitrary code execution, MCP provides a controlled interface where:

1. **Tools are predefined**: The MCP server exposes specific functions (e.g., `get_products_by_name`, `get_customer_sales_summary`)
2. **Security is enforced**: The AI can only call approved functions with validated parameters
3. **Modularity is enabled**: New capabilities can be added by extending the MCP server without modifying the AI model

#### MCP Tools in This Application

| Tool | Description |
|------|-------------|
| `get_products_by_name` | Search products by keyword or description |
| `get_customer_sales_summary` | Retrieve customer purchase history |
| `get_schema_information` | Query database structure for context |

#### Request Flow

```
1. User Query     →  "Show me cordless drills under $200"
2. AI Reasoning   →  Determines need to search product database
3. MCP Tool Call  →  get_products_by_name("cordless drill", max_price=200)
4. Database Query →  SQL executed on PostgreSQL with pgvector
5. Response       →  Formatted product recommendations returned to user
```

### 🧠 Learning Outcomes

By the end of this session, learners will be able to:

- Explore and compare models with the AI Toolkit Playground; iterate over prompts using the Agent Builder and evaluate results on a test dataset.
- Move from prototype to code, combining your models and prompts with your app code with Visual Studio Code and Microsoft Foundry.
- Go smoothly into production by leveraging pre-built enterprise-ready features of Microsoft Foundry to deploy, safeguard and monitor your AI agent over time.

### 💻 Technologies Used

1. Visual Studio Code
1. AI Toolkit extension for Visual Studio Code
1. GitHub Copilot Agent Mode
1. GitHub Copilot for Azure

### 🔗 Session Resources
| Resources          | Links                             | Description        |
|:-------------------|:----------------------------------|:-------------------|
| AI Toolkit | https://aka.ms/AIToolkit |  A comprehensive extension that empowers developers and AI engineers to build, test, and deploy intelligent applications using generative AI models |
| GitHub Copilot Agent Mode | https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode |  With chat agent mode in Visual Studio Code, you can use natural language to specify a high-level task, and let AI autonomously reason about the request, plan the work needed, and apply the changes to your codebase. |
| GitHub Copilot for Azure | https://learn.microsoft.com/azure/developer/github-copilot-azure/get-started |  Get started with GitHub Copilot for Azure to streamline your development workflow and enhance your productivity on the Azure platform. |

### 📚 Continued Learning Resources
| Resources          | Links                             | Description        |
|:-------------------|:----------------------------------|:-------------------|
| AI Tour 2026 Resource Center | https://aka.ms/AITour26-Resource-center | Links to all repos for AI Tour 26 Sessions |
| Microsoft Foundry Community Discord | [![Microsoft Foundry Discord](https://dcbadge.limes.pink/api/server/Pwpvf3TWaw)](https://aka.ms/MicrosoftFoundryDiscord-AITour26)| Connect with the Azure AI Foundry Community! |
| Learn at AI Tour | https://aka.ms/LearnAtAITour | Continue learning on Microsoft Learn |

---

## 🚀 Azure Container Apps Deployment

This branch (`azure-container-apps-deployment`) contains the infrastructure and configuration to deploy the Cora AI Agent to Azure Container Apps using the Azure Developer CLI (azd).

### Deployment Status

| Component | Status | Notes |
|-----------|--------|-------|
| Container App | ✅ Verified | Auto-scaling enabled |
| PostgreSQL | ✅ Verified | pgvector extension with retail schema |
| AI Models | ✅ Verified | gpt-4o-mini + text-embedding-3-small |
| Database Restore | ✅ Automated | Via postprovision hook |
| Managed Identity | ✅ Verified | No API keys required |

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Azure Resource Group                            │
│                         (rg-{environment-name})                         │
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │  Container App  │────│  Container      │    │  Log Analytics  │     │
│  │  (Cora Web App) │    │  Registry (ACR) │    │  Workspace      │     │
│  └────────┬────────┘    └─────────────────┘    └─────────────────┘     │
│           │                                                             │
│           │ Managed Identity                                            │
│           ▼                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │  Azure AI       │    │  PostgreSQL     │    │  Application    │     │
│  │  Foundry        │    │  Flexible Server│    │  Insights       │     │
│  │  (gpt-4o-mini)  │    │  (pgvector)     │    │                 │     │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Docker Desktop](https://www.docker.com/products/docker-desktop) - Required for container builds and database restore
- Azure subscription with sufficient quota for:
  - Azure AI Foundry (gpt-4o-mini, text-embedding-3-small)
  - Azure Database for PostgreSQL Flexible Server
  - Azure Container Apps

### Quick Start

1. **Login to Azure:**
   ```bash
   az login
   azd auth login
   ```

2. **Initialize environment (first time only):**
   ```bash
   azd init
   ```

3. **Set location (recommended: East US 2):**
   ```bash
   # Note: East US may be restricted for PostgreSQL in some subscriptions
   azd env set AZURE_LOCATION eastus2
   ```

4. **Deploy everything:**
   ```bash
   azd up --no-prompt
   ```
   
   This command will:
   - Build the Docker container
   - Provision all Azure resources (~8-10 minutes)
   - Restore the PostgreSQL database with product data (via postprovision hook)
   - Deploy the container to Azure Container Apps

5. **Access the application:**
   ```bash
   # Get the deployed URL
   azd env get-values | grep SERVICE_WEB_APP_URI
   ```

### Manual Database Restore (if needed)

If the postprovision hook doesn't run automatically, restore the database manually:

```powershell
# Get connection details
$env = azd env get-values | ConvertFrom-StringData

# Run pg_restore using Docker
docker run --rm `
  -v "${PWD}/data/zava_retail_2025_07_21_postgres_rls.backup:/backup.dump:ro" `
  -e "PGPASSWORD=$($env.POSTGRES_ADMIN_PASSWORD)" `
  postgres:17 `
  pg_restore `
  --host="$($env.POSTGRES_SERVER_NAME).postgres.database.azure.com" `
  --port=5432 `
  --username=zadmin `
  --dbname=zava `
  --verbose `
  --no-owner `
  --no-privileges `
  --if-exists `
  --clean `
  /backup.dump
```

### Known Issues & Workarounds

| Issue | Solution |
|-------|----------|
| PostgreSQL "LocationIsOfferRestricted" error | Use `eastus2` instead of `eastus`: `azd env set AZURE_LOCATION eastus2` |
| `transaction_timeout` warning during restore | Safe to ignore - PostgreSQL 17 feature not supported on Azure |
| Resource group deletion still in progress | Wait 2-3 minutes and retry `azd up` |

### Infrastructure Components

| Component | Description | Provisioning Time |
|-----------|-------------|-------------------|
| **Container Apps Environment** | Serverless container hosting with auto-scaling | ~40s |
| **Container App** | Cora web application | ~25s |
| **Container Registry** | Private ACR for Docker images with managed identity pull | ~30s |
| **Azure AI Foundry** | GPT-4o-mini and text-embedding-3-small model deployments | ~2s |
| **PostgreSQL Flexible Server** | Database with pgvector extension for embeddings | ~4m |
| **Managed Identity** | Secure authentication to AI Foundry (no API keys!) | ~5s |
| **Application Insights** | Monitoring and telemetry | ~10s |
| **Log Analytics Workspace** | Centralized logging | ~10s |

**Total deployment time: ~10-12 minutes**

### Key Files Added

```
├── Dockerfile                    # Multi-stage Docker build for web app
├── Dockerfile.mcp                # MCP server Docker build
├── docker-compose.yml            # Basic local development
├── docker-compose.full.yml       # Full local development with all services
├── docker-start.ps1              # PowerShell script for Docker startup
├── azure.yaml                    # Azure Developer CLI configuration with hooks
├── DOCKER.md                     # Docker documentation
├── .env.docker                   # Environment template for local Docker development
└── infra/
    ├── main.bicep                # Main infrastructure orchestration
    ├── main.parameters.json      # Default parameters
    ├── container-apps.bicep      # Container Apps Environment & App
    ├── container-registry.bicep  # ACR with managed identity
    ├── postgresql.bicep          # PostgreSQL with pgvector
    ├── foundry.bicep             # Azure AI Foundry hub
    ├── foundry-project.bicep     # AI Foundry project
    ├── foundry-model-deployment.bicep  # Model deployments
    ├── managed-identity.bicep    # User-assigned managed identity
    ├── ai-foundry-role-assignment.bicep  # RBAC for AI Foundry
    ├── application-insights.bicep # App Insights resource
    ├── log-analytics.bicep       # Monitoring workspace
    ├── deploy.ps1                # PowerShell deployment script
    └── deploy.sh                 # Bash deployment script
```

### Code Changes for Azure Deployment

1. **Managed Identity Authentication** - Updated `web_app.py` to use `ManagedIdentityCredential` instead of API keys when running in Azure
2. **MCP Environment Variables** - Pass `POSTGRES_URL` to MCP subprocess via `env` parameter for database connectivity
3. **Health Checks** - Container app includes liveness and readiness probes at `/health`

### Local Development with Docker

```bash
# Copy environment template
cp .env.docker .env

# Edit .env with your Azure AI Foundry values
# Get an access token
az account get-access-token --resource "https://ai.azure.com" --query accessToken -o tsv

# Start the application
docker-compose -f docker-compose.full.yml up --build
```

### Useful Commands

```bash
# View deployment status
azd env get-values

# View container logs
az containerapp logs show -n <container-app-name> -g <resource-group> --tail 100

# Restart the container app
az containerapp revision restart -n <container-app-name> -g <resource-group> --revision <revision-name>

# Redeploy after code changes
azd deploy

# View all deployed resources
az resource list -g <resource-group> -o table

# Tear down all resources (with confirmation)
azd down

# Force tear down and purge soft-deleted resources
azd down --force --purge
```

### Environment Variables Set by Deployment

| Variable | Description |
|----------|-------------|
| `PROJECT_ENDPOINT` | Azure AI Foundry project endpoint |
| `GPT_MODEL_DEPLOYMENT_NAME` | gpt-4o-mini deployment name |
| `EMBEDDING_MODEL_DEPLOYMENT_NAME` | text-embedding-3-small deployment name |
| `POSTGRES_SERVER_NAME` | PostgreSQL server hostname |
| `POSTGRES_DATABASE_NAME` | Database name (zava) |
| `POSTGRES_ADMIN_PASSWORD` | Admin password (auto-generated) |
| `AZURE_CLIENT_ID` | Managed identity client ID |
| `SERVICE_WEB_APP_URI` | Deployed application URL |

### Security Features

- ✅ **Managed Identity** - No API keys or secrets in code; uses `ManagedIdentityCredential`
- ✅ **Private Container Registry** - Images stored in private ACR with managed identity pull
- ✅ **HTTPS Only** - Container App ingress requires HTTPS
- ✅ **RBAC** - Least-privilege access with Cognitive Services User role
- ✅ **Secure Database** - PostgreSQL with SSL enforcement and firewall rules
- ✅ **Row Level Security** - Database includes RLS policies for multi-tenant data access

### Testing the Deployment

After deployment, test Cora by asking questions like:
- "What drills do you have?"
- "Show me products under $50"
- "What stores are available?"
- "Tell me about cordless power tools"

### 🌐 Multi-Language Support

Additional languages are coming soon.

## Content Owners

<table>
<tr>
    <td align="center"><a href="https://github.com/roryp">
        <img src="https://github.com/roryp.png" width="100px;" alt="Rory Preddy"/><br />
        <sub><b>Rory Preddy</b></sub></a><br />
            <a href="https://github.com/roryp" title="talk">📢</a> 
    </td>
</tr></table>

## Responsible AI 

Microsoft is committed to helping our customers use our AI products responsibly, sharing our learnings, and building trust-based partnerships through tools like Transparency Notes and Impact Assessments. Many of these resources can be found at [https://aka.ms/RAI](https://aka.ms/RAI).
Microsoft’s approach to responsible AI is grounded in our AI principles of fairness, reliability and safety, privacy and security, inclusiveness, transparency, and accountability.

Large-scale natural language, image, and speech models - like the ones used in this sample - can potentially behave in ways that are unfair, unreliable, or offensive, in turn causing harms. Please consult the [Azure OpenAI service Transparency note](https://learn.microsoft.com/legal/cognitive-services/openai/transparency-note?tabs=text) to be informed about risks and limitations.

The recommended approach to mitigating these risks is to include a safety system in your architecture that can detect and prevent harmful behavior. [Azure AI Content Safety](https://learn.microsoft.com/azure/ai-services/content-safety/overview) provides an independent layer of protection, able to detect harmful user-generated and AI-generated content in applications and services. Azure AI Content Safety includes text and image APIs that allow you to detect material that is harmful. Within Azure AI Foundry portal, the Content Safety service allows you to view, explore and try out sample code for detecting harmful content across different modalities. The following [quickstart documentation](https://learn.microsoft.com/azure/ai-services/content-safety/quickstart-text?tabs=visual-studio%2Clinux&pivots=programming-language-rest) guides you through making requests to the service.

Another aspect to take into account is the overall application performance. With multi-modal and multi-models applications, we consider performance to mean that the system performs as you and your users expect, including not generating harmful outputs. It's important to assess the performance of your overall application using [Performance and Quality and Risk and Safety evaluators](https://learn.microsoft.com/azure/ai-studio/concepts/evaluation-metrics-built-in). You also have the ability to create and evaluate with [custom evaluators](https://learn.microsoft.com/azure/ai-studio/how-to/develop/evaluate-sdk#custom-evaluators).

You can evaluate your AI application in your development environment using the [Azure AI Evaluation SDK](https://microsoft.github.io/promptflow/index.html). Given either a test dataset or a target, your generative AI application generations are quantitatively measured with built-in evaluators or custom evaluators of your choice. To get started with the azure ai evaluation sdk to evaluate your system, you can follow the [quickstart guide](https://learn.microsoft.com/azure/ai-studio/how-to/develop/flow-evaluate-sdk). Once you execute an evaluation run, you can [visualize the results in Azure AI Foundry portal ](https://learn.microsoft.com/azure/ai-studio/how-to/evaluate-flow-results).
