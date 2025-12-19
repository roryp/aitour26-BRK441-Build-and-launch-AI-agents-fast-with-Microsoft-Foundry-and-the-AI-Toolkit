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

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Azure Resource Group                            │
│                         (rg-zava-cora-dev)                              │
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
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- Azure subscription with sufficient quota for AI models

### Quick Start

1. **Login to Azure:**
   ```bash
   az login
   azd auth login
   ```

2. **Initialize and deploy:**
   ```bash
   azd init
   azd up
   ```

3. **Access the application:**
   After deployment, the Container App URL will be displayed (e.g., `https://ca-cora-xxx.azurecontainerapps.io`)

### Infrastructure Components

| Component | Description |
|-----------|-------------|
| **Container Apps Environment** | Serverless container hosting with auto-scaling |
| **Container Registry** | Private ACR for Docker images with managed identity pull |
| **Azure AI Foundry** | GPT-4o-mini and text-embedding-3-small model deployments |
| **PostgreSQL Flexible Server** | Database with pgvector extension for embeddings |
| **Managed Identity** | Secure authentication to AI Foundry (no API keys!) |
| **Application Insights** | Monitoring and telemetry |
| **Log Analytics Workspace** | Centralized logging |

### Key Files Added

```
├── Dockerfile                    # Multi-stage Docker build for web app
├── docker-compose.full.yml       # Local development with Docker
├── azure.yaml                    # Azure Developer CLI configuration
├── DOCKER.md                     # Docker documentation
└── infra/
    ├── main.bicep                # Main infrastructure orchestration
    ├── container-apps.bicep      # Container Apps Environment & App
    ├── container-registry.bicep  # ACR with managed identity
    ├── postgresql.bicep          # PostgreSQL with pgvector
    ├── managed-identity.bicep    # User-assigned managed identity
    ├── ai-foundry-role-assignment.bicep  # RBAC for AI Foundry
    └── log-analytics.bicep       # Monitoring workspace
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
# View container logs
az containerapp logs show -n ca-cora-xxx -g rg-zava-cora-dev --tail 100

# Redeploy after code changes
azd deploy

# View all deployed resources
az resource list -g rg-zava-cora-dev -o table

# Remove delete lock (if needed for cleanup)
az lock delete --name DoNotDelete-ZavaCora --resource-group rg-zava-cora-dev

# Tear down all resources
azd down
```

### Security Features

- ✅ **Managed Identity** - No API keys or secrets in code
- ✅ **Private Container Registry** - Images stored in private ACR
- ✅ **Delete Lock** - Resource group protected from accidental deletion
- ✅ **HTTPS Only** - Container App ingress requires HTTPS
- ✅ **RBAC** - Least-privilege access with Cognitive Services User role

### 🌐 Multi-Language Support

Additional languages are coming soon.

## Content Owners

<!-- TODO: Add yourself as a content owner
1. Change the src in the image tag to {your github url}.png
2. Change INSERT NAME HERE to your name
3. Change the github url in the final href to your url. -->


<table>
<tr>
    <td align="center"><a href="http://github.com/aprilgitens">
        <img src="https://github.com/aprilgittens.png" width="100px;" alt="April Gittens"
"/><br />
        <sub><b> April Gittens
</b></sub></a><br />
            <a href="https://github.com/aprilgittens" title="talk">📢</a> 
    </td>
    <td align="center"><a href="http://github.com/bethanyjep">
        <img src="https://github.com/bethanyjep.png" width="100px;" alt="Bethany Jepchumba"/><br />
        <sub><b>Bethany Jepchumba
</b></sub></a><br />
            <a href="https://github.com/bethanyjep" title="talk">📢</a> 
    </td>
</tr></table>

## 

## Responsible AI 

Microsoft is committed to helping our customers use our AI products responsibly, sharing our learnings, and building trust-based partnerships through tools like Transparency Notes and Impact Assessments. Many of these resources can be found at [https://aka.ms/RAI](https://aka.ms/RAI).
Microsoft’s approach to responsible AI is grounded in our AI principles of fairness, reliability and safety, privacy and security, inclusiveness, transparency, and accountability.

Large-scale natural language, image, and speech models - like the ones used in this sample - can potentially behave in ways that are unfair, unreliable, or offensive, in turn causing harms. Please consult the [Azure OpenAI service Transparency note](https://learn.microsoft.com/legal/cognitive-services/openai/transparency-note?tabs=text) to be informed about risks and limitations.

The recommended approach to mitigating these risks is to include a safety system in your architecture that can detect and prevent harmful behavior. [Azure AI Content Safety](https://learn.microsoft.com/azure/ai-services/content-safety/overview) provides an independent layer of protection, able to detect harmful user-generated and AI-generated content in applications and services. Azure AI Content Safety includes text and image APIs that allow you to detect material that is harmful. Within Azure AI Foundry portal, the Content Safety service allows you to view, explore and try out sample code for detecting harmful content across different modalities. The following [quickstart documentation](https://learn.microsoft.com/azure/ai-services/content-safety/quickstart-text?tabs=visual-studio%2Clinux&pivots=programming-language-rest) guides you through making requests to the service.

Another aspect to take into account is the overall application performance. With multi-modal and multi-models applications, we consider performance to mean that the system performs as you and your users expect, including not generating harmful outputs. It's important to assess the performance of your overall application using [Performance and Quality and Risk and Safety evaluators](https://learn.microsoft.com/azure/ai-studio/concepts/evaluation-metrics-built-in). You also have the ability to create and evaluate with [custom evaluators](https://learn.microsoft.com/azure/ai-studio/how-to/develop/evaluate-sdk#custom-evaluators).

You can evaluate your AI application in your development environment using the [Azure AI Evaluation SDK](https://microsoft.github.io/promptflow/index.html). Given either a test dataset or a target, your generative AI application generations are quantitatively measured with built-in evaluators or custom evaluators of your choice. To get started with the azure ai evaluation sdk to evaluate your system, you can follow the [quickstart guide](https://learn.microsoft.com/azure/ai-studio/how-to/develop/flow-evaluate-sdk). Once you execute an evaluation run, you can [visualize the results in Azure AI Foundry portal ](https://learn.microsoft.com/azure/ai-studio/how-to/evaluate-flow-results).
