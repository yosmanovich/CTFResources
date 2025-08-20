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

## Prerequisites
- [Python](https://www.python.org/downloads/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [AZ CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest)
- [Visual Studio Code](https://code.visualstudio.com/)

  ```bash
  dotnet add package ModelContextProtocol --prerelease
  ```

## Create and populate the Configuration file
Copy the Configuration\Environment.json file to Configuration\Dev.json (or Configuration\Test.json or Configuration\Staging.json or Configuration\Prod.json).

For Local Deployments
You must only configure the *ContainerRegistryName* and then run this locally

For Azure Deployments
You *must* configure all the properties

## Local Development

### Run the Server Locally

1. Navigate to the project directory
   ```bash
   cd DeploymentScripts
   .\Build-Containers.ps1 -Environment <Environment Name>
   ```
2. The servers will be available at `http://localhost:5000`

## Deploy to Azure

1. Login to Azure:
   ```bash
   az login
   ```
3. Deploy the resources:
   ```bash
    cd DeploymentScripts
   .\Deploy-ARMTemplates.ps1 -Environment <Environment Name>
   ```
   This will:
   - Provision Azure resources 
   - Build the containers
   - Deploy the containers

   Once this completes you will have an environment fully hosted within Azure with the Ollama, Ollama Proxy, Ollama GUI, and the chainlit applications