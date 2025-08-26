# Ollama and Everything else

This project contains ARM templates for hosting several services within Azure, Docker resources, and python code. 

## Key Features

- Azure App Service integration
- Custom tools support

## Project Structure
- `Configuration/` - Configuration Files for your Development, Test, Staging, and Production environments
  - `Environment.json` - The started Environment file; copy it locally as Dev, Test, Staging, and/or Prod 
- `src/` - Contains Python code used within this project
  - `chainlit/` - Contains a simple chat application
    - `app.py` - The entry point for the simple chat application
- `DeploymentScripts/` - The MCP Local Server that runs via stdio
  - `Build-Containers.ps1` - The build script for the docker containers
  - `Deploy-ARMTemplates.ps1` - The infrastructure deployment script
- `Infrastructure/` - The MCP Server that runs via HTTP/HTTPS
  - `Templates` - The ARM Templates for the solution resources
    - `ContainerApp.json` - The template for a ContainerApp resource
    - `ContainerAppsEnvironment.json` - The template for a Container App Environment resource
    - `ContainerRegistry.json` - The template for a Container Registry resource
    - `KeyVault.json` - The template for a Key Vault resource
    - `LogAnalytics.json` - The template for a Log Analytics resource
    - `StorageAccount.json` - The template for a Storage Account resource
  - `Parameters` - The ARM Templates for the solution    
    - `ContainerApp.chainlit.parameters.json` - The parameters for the chainlit container app
    - `ContainerApp.ollama-gui.parameters.json` - The parameters for the ollama gui container app
    - `ContainerApp.ollama-proxy.parameters.json` - The parameters for the ollama proxy container app
    - `ContainerApp.ollama.parameters.json` - The parameters for the ollama container app
    - `ContainerAppsEnvironment.parameters.json` - The parameters for the container app environment
    - `ContainerRegistry.parameters.json` - The parameters for the container registry
    - `KeyVault.parameters.json` - The parameters for the keyvault
    - `LogAnalytics.parameters.json` - The parameters for the log analytics workspace
    - `StorageAccount.parameters.json` - The parameters for the storage account
  - `Containers` - The resources needed for the Containers
    - `.nginx` - The directory containing the Nginx files
      - `nginx.conf.template` - The template file for the nginx configuration
    - `docker-compose.yaml` - The docker compose yaml file
    - `chainlit-Dockerfile` - The docker file defining what is needed for the chainlit container
    - `ollama-Dockerfile` - The docker file defining what is needed for the Ollama container
    - `ollama-gui-Dockerfile` - The docker file defining what is needed for the Ollama GUI container
    - `ollama-proxy-Dockerfile` - The docker file defining what is needed for the Nginx / Ollama Proxy container
  - `Documentation` - Additional documents for this project
    - `Media` - Images for the documenation for this project
## Prerequisites
- [Python](https://www.python.org/downloads/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [AZ CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest)
- [Visual Studio Code](https://code.visualstudio.com/)

## I just want to get this running

### Open a Cloudshell in the Azure Portal

Log into Azure via the portal. 
Once in, open a Cloud Shell - this can be done by clicking the cloudshell button on the upper bar.
![CLI](Documentation\Media\CLI.png "CLI")
At the Welcome to Azure Cloud Shell message, click *PowerShell* 
![Welcome to Cloudshell](Documentation\Media\1.Welcome.png "Welcome to Cloudshell")

At the Getting started screen, select *Mount storage account* and select your storage account subscription, click *Apply*
![Select Subscription](Documentation\Media\2.SelectSubscription.png "Select Subscription")

At the Mount storage account screen, select *We will create a storage account for you* and click *Next*
Note: If you have a storage account with a file share that you can use for your cloud shell, feel free to use that. The method we identified is the "easy" approach.
![Select Storage](Documentation\Media\3.Storage.png "Select Storage")

Azure will provision a cloud shell and you will soon have a prompt.

### Clone the repository and Deploy the resources
Running the 
   ```bash
   cd clouddrive
   git clone https://github.com/yosmanovich/CTFResources.git
   cd CTFResources/DeploymentScripts
   .\Deploy-ARMTemplates.ps1 -DeployInCloudShell -InitializeEnvironmentFile
   ```


## Create and populate the Configuration file
Copy the Configuration\Environment.json file to Configuration\Dev.json (or Configuration\Test.json or Configuration\Staging.json or Configuration\Prod.json).

For Local Deployments
You must only configure the *ContainerRegistryName* and then run this locally

For Azure Deployments
You *must* configure all the properties

## Containers

### Ollama 
The Ollama container runs the [Ollama application](https://ollama.com/). This provides direct access to LLMS via a mounted volume. Ollama does not provide any authentication capabilities therefore it should not be exposed on the public Internet. The APIs within Ollama enable a non-authenticated user to make any and all function calls to the system including creating and adding additional LLMS. Access to Ollama from the Internet should be done either through the Ollama Proxy or other applications.

The Ollama API may be reviewed at  [Ollama API](https://github.com/ollama/ollama/blob/main/docs/api.md)

### Ollama GUI
The Ollama GUI container runs the [Ollama GUI application](https://github.com/ollama-webui). This application is also not very secure as users may register themselves and then be given access. T

### Ollama Proxy
The Ollama Proxy container runs an [NGINX](https://nginx.org/) reverse proxy server. This application retrieves two secrets from an Azure Key Vault to serve as API Keys for accessing the Ollama backend. The two keys are a User Key and an Admin Key and are set when the deployment occurs. A copy of each key presented at the end of the deployment and the keys may be obtained by reviewing the secrets in the Key Vault.

|API Endpoint| HTTP Operation | User Key Access | Admin Key Access
| ---------- | -------------- | ------ | - |
| /api/chat | POST | &check; | &check;
| /api/generate | POST | &check; | &check;
| /api/ps | POST | &check; | &check;
| /api/show | POST | &check; | &check;
| /api/tags | GET | &check; | &check;
| /api/blobs | POST |   | &check;
| /api/copy  | POST |   | &check;
| /api/create | POST |   | &check;
| /api/delete | DELETE |  | &check;
| /api/embed | POST |  | &check;
| /api/embeddings | POST |  | &check;
| /api/pull | POST |  | &check;
| /api/push | POST |  | &check;
| /api/version | GET |  | &check;

### Chainlit
The chainlit container runs an [Chainlit](https://docs.chainlit.io/) server.

## Local Development

### Run the Server Locally

1. Navigate to the project directory
   ```bash
   cd DeploymentScripts
   .\Build-Containers.ps1 -Environment <Environment Name>
   ```
2. The servers will be available through Docker
   - Ollama will be available at: http://localhost:11434
   - Ollama GUI will be available at: http://localhost:8080
   - Ollama Proxy be available at: http://localhost
   - Chainlit will be available at: http://localhost:8081

## Deploy to Azure
This deployment will create the following infrastructure within your Azure environment. 
![Deployed Infrastructure](Documentation\Media\Infrastructure.jpg "Infrastructure")
1. Login to Azure:
   ```bash
   az login
   ```
2. Deploy the resources:
   ```bash
    cd DeploymentScripts
   .\Deploy-ARMTemplates.ps1 -Environment <Environment Name>
   ```
   This will:
   - Provision Azure resources 
   - Build the containers
   - Deploy the containers

   Once this completes you will have an environment fully hosted within Azure with the Ollama, Ollama Proxy, Ollama GUI, and the chainlit applications
### Redeploy Containers to Azure
After the infrastructure is built, you can re-deploy changes you made to the containers by running the following command: 
```bash
 cd DeploymentScripts
 .\Build-Containers.ps1 -Environment <Environment Name> -AzureDeployment $true
 ```