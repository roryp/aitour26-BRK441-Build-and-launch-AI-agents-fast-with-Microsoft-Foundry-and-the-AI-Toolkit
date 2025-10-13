## How to deliver this session

🥇 Thanks for delivering this session!

Prior to delivering the workshop please:

1.  Read this document and all included resources included in their entirety.
2.  Watch the video presentation
3.  Ask questions of the content leads! We're here to help!


## 📁 File Summary

| Resources          | Links                            | Description |
|-------------------|----------------------------------|-------------------|
| Session Delivery Deck     |  [Deck](https://aka.ms/AAxryus) | The session delivery slides |
| Full Session | [Recording Link](aka.ms/AAxq4rj) | The full session presentation |



## 🚀Get Started

The breakout is divided into multiple sections including 32 slides and 6 demos.

### 🕐Timing

| Time        | Description 
--------------|-------------
0:00 - 3:12   | Intro and overview
3:13 - 4:41   | GenAI ops
4:42 - 10:39   | Meet the models
10:40 - 18:07   | Design your agent
18:08 - 30:02   | Evaluate your agent responses
30:03 - 37:13   | From prototype to production
37:14 - 41:00  | Wrap up and Q&A

### 🖥️Demos

| Demo        | Description | Video 
--------------|-------------|-------------
[Explore and compare models](/docs/demos/explore-compare-models.md)   | Browse the model **Catalog** in the AI Toolkit and compare 2 models within the **Playground** | [Demo video](https://aka.ms/AAxqj4z)
[Create agents with Agent Builder](/docs/demos/create-agents.md)   | Create the Cora agent in the **Agent Builder** and define it's system prompt |  [Demo video](https://aka.ms/AAxq4rm)
[Add tools to an agent in Agent Builder](/docs/demos/add-tools.md)   | Connect the Cora agent to the **Zava MCP server** and add the **get_products_by_name** tool | [Demo video](https://aka.ms/AAxqc9k)
[Evaluate agent responses](/docs/demos/evaluate-agent-responses.md)   | Run both manual and AI-assisted evaluations for the agent output | [Demo video](https://aka.ms/AAxqc9h)
[Export agent code](/docs/demos/export-agent-code.md)   | Export the code from the **Agent Builder** for the Cora agent | [Demo video](https://aka.ms/AAxq4rl)
[Cora app](/docs/demos/cora-app.md)   | Chat with the Cora agent live via the agent UI | [Demo video](https://aka.ms/AAxqj51)

### 🏋️Preparation
This demo is designed to be run in a development container for easy setup. The container includes the following:
- PostgresSQL dataset for Zava
- **Customer Sales Server** that does basic product search using traditional name-based matching
- A web app of the Cora agent app

#### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed
- Azure AI Foundry project with a **GPT-4o** model deployment
- [Visual Studio Code](https://code.visualstudio.com)

**Open the repository in the dev container**

1. Open **Docker Desktop**.
1. Fork and clone this repository in Visual Studio Code.
1. When prompted by Visual Studio Code, select to "Reopen in Container". Alternatively, open the **Command Palette** (i.e. CTRL/CMD+Shift+P) and enter **Dev Containers: Reopen in Container**.
1. Wait for the setup to complete. The dev container will build automatically with all dependencies pre-installed. This includes PostgresSQL with pgvector extension, a Python environment, and all required packages.

**Confirm extensions are installed**

Confirm that the dev container has installed the following extensions:
- [Azure Resources](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureresourcegroups)
- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [AI Toolkit](https://aka.ms/AIToolkit)

If any extension is missing, install before moving forward.

*Note: The [Azure AI Foundry](https://marketplace.visualstudio.com/items?itemName=TeamsDevApp.vscode-ai-foundry) extension is installed as a bundle with the AI Toolkit*.

**Sign-in to the Azure Resources extension and set your default project.**

1. In the **Azure Resources** extension, select **Sign in to Azure**.
1. Sign-in to the account that has your Azure AI Foundry project and GPT-4o deployed model.
1. Open the **Azure AI Foundry** extension (*note: the Azure AI Foundry extension comes installed with the AI Toolkit*).
1. Under the **Resources** section, confirm whether your Azure AI Foundry project is set as the default project. The default project displays under **Resources** with a **Default** label.
1. If your project is **not** set as the default project, hover over the project name and click the **Switch Default Project in Azure Extension** icon (*note: the icon looks like 3 lines*).
1. In the **Pick a project** window, select the subscription that has your Azure AI Foundry project.
1. In the **Pick a project** window, select your Azure AI Foundry project.

**Setup environment variables**
1. In the terminal, run the command: `cp .env.example .env`
1. Open your new `.env` file.
1. Enter your `AZURE_AI_API_KEY="<your_Azure_AI_API_key>"` (note: The **Key** in the **Endpoint** section for your model deployment )
1. Enter your `AZURE_AI_ENDPOINT="<your_Azure_AI_endpoint>"` (note: The **Target URI** in the Endpoint section for your model deployment up until the deployment name; ex: https://{your-custom-endpoint}-resource.cognitiveservices.azure.com/openai/deployments/gpt-4o)

**Start the Customer Sales Server**

1. Navigate to the **.vscode/mcp.json** file.
1. Click **Start** above the **zava-customer-sales-stdio** server.

**Start the Cora web app**

1. In the terminal, run the command `python src/python/web_app/web_app.py`.
1. In the browser, navigate to [htts://localhost:8000](http://localhost:8000).
1. Confirm that the green **Connected** label displays in the top-right of the UI.

**Create 4 iterations of the Cora agent within the AI Toolkit**

Although you can create the agent live during the demo, it's recommend to already have saved verisons of the Cora agent prepared to mitigate latency or errors with setup.

***V1 Agent***

1. In the AI Toolkit, navigate to the **Agent Builder**.
2. Create a new agent named **Cora**.
3. For the **Model** field, select **gpt-4o**.
4. For the **Instructions** field, enter the following:

  ```
  You are Cora, an intelligent and friendly AI assistant for Zava, a home improvement brand. You help customers with their DIY projects by understanding their needs and recommending the most suitable products from Zava’s catalog.​
  
  Your role is to:​
  
  - Engage with the customer in natural conversation to understand their DIY goals.​
  
  - Ask thoughtful questions to gather relevant project details.​
  
  - Be brief in your responses.​
  
  - Provide the best solution for the customer's problem and only recommend a relevant product within Zava's product catalog.​
  
  - Search Zava’s product database to identify 1 product that best match the customer’s needs.​
  
  - Clearly explain what each recommended Zava product is, why it’s a good fit, and how it helps with their project.​
  ​
  Your personality is:​
  
  - Warm and welcoming, like a helpful store associate​
  
  - Professional and knowledgeable, like a seasoned DIY expert​
  
  - Curious and conversational—never assume, always clarify​
  
  - Transparent and honest—if something isn’t available, offer support anyway​
  
  If no matching products are found in Zava’s catalog, say:​
  “Thanks for sharing those details! I’ve searched our catalog, but it looks like we don’t currently have a product that fits your exact needs. If you'd like, I can suggest some alternatives or help you adjust your project requirements to see if something similar might work.”​
  ```
5. Scroll to the bottom of the Agent Builder and select **Save Version**. Name the version **v1**.

***V2 Agent***

1. From the **v1 agent**, clear the chat window.
2. Scroll to the bottom of the Agent Builder and select **Save Version**. Name the version **v2**. 

***V3 Agent Manual Evaluation***

1. From the **v2** agent, switch to the **Evaluation** tab.
2. Enter the following for the **User Query** and **{{product}}** values for each row of data:

|   User Query        | {{product}} 
--------------|-------------
What type of {{product}} does Zava have?   | organic compost
Does Zava have a {{product}}? If so, how much is it?  | paint bucket
What color {{product}} does Zava sell?  | glitter
How many {{product}} is currently in stock?   | tape measure

3. Scroll down to the bottom of the Agent Builder and select **Save Version**. Name the version **v3-manual-evaluation**.

***V4 Agent Automated Evaluation***

*Note: Running automated evaluations can take a significant amount of time. It is recommended to run this evaluation in advanced.*

1. From the **v3-manual-evaluation** agent, create a new evaluation via the **Add Evaluation** button.
2. Select the following evaluators: intent resolution, task adherence, coherence.
3. Select the **gpt-4o**  model.
4. Run the **Run Evaluation** > **Run Evaluation Only**.
5. Scroll down to the bottom of the Agent Builder and select **Save Version**. Name the version **v4-automated-evaluation**.
   
