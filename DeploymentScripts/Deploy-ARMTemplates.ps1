param(
    [Parameter()]    
    [ValidateSet('Dev','Test','Staging','Prod')]
    [string]$Environment = "Dev",
    [Parameter()]    
    [ValidateSet('$command','what-if')]
    [string]$command = "create"
)
    
function Get-RandomKey {
    return [Guid]::NewGuid().ToString('N').Substring(0, 16)
}

if (Test-Path -Path "../Configuration/$Environment.json")
{
    az config set extension.use_dynamic_install=yes_without_prompt

    $EnvironmentSettings = (Get-Content "../Configuration/$Environment.json" -Raw) | ConvertFrom-Json
    
    $resourceGroupName = az group show --name  $($EnvironmentSettings.ResourceGroupName) --query name -o tsv
    if ($null -eq $resourceGroupName)
    {
        az group $command --name $($EnvironmentSettings.ResourceGroupName) --location $($EnvironmentSettings.Location) --output none
    }

    az deployment group $command --name "keyvault" `
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --template-file "../Infrastructure/Templates/KeyVault.json" `
        --parameters "../Infrastructure/Parameters/KeyVault.parameters.json" `
        --parameters "vaultName=$($EnvironmentSettings.KeyVaultName)"  `
        --output none
    Write-Host "Key Vault provisioned"

    $scope = az keyvault show --resource-group  $($EnvironmentSettings.ResourceGroupName) --name $($EnvironmentSettings.KeyVaultName) --query id -o tsv

    $upn = az ad signed-in-user show --query id -o tsv
    az role assignment $command --role  "Key Vault Secrets Officer" --assignee $upn --scope $scope --output none
    
    $requiredSecrets = @{
       "OLLAMA-ADMIN-KEY" = "Not Set"
       "OLLAMA-USER-KEY"  = "Not Set"
    }

    $secrets = az keyvault secret list --vault-name $($EnvironmentSettings.KeyVaultName) --query "[].name" -o tsv
    $keys = @($requiredSecrets.Keys)
    $keys | ForEach-Object {    
        if ($secrets -notcontains $_)
        {
            $requiredSecrets[$_] = Get-RandomKey
            az keyvault secret set --vault-name $($EnvironmentSettings.KeyVaultName) --name $_ --value $requiredSecrets[$_] --output none
        }
    }

    az deployment group $command --name "storage" `
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --template-file "../Infrastructure/Templates/StorageAccount.json" `
        --parameters "../Infrastructure/Parameters/StorageAccount.parameters.json" `
        --parameters "storageAccount_name=$($EnvironmentSettings.StorageAccountName)"  `
        --output none
    Write-Host "Storage Account provisioned"

    az deployment group $command --name "loganalytics" `
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --template-file "../Infrastructure/Templates/LogAnalytics.json" `
        --parameters "../Infrastructure/Parameters/LogAnalytics.parameters.json" `
        --parameters "analyticWorkspaceName=$($EnvironmentSettings.LogAnalyticsName)"  `
        --output none
    Write-Host "Log Analytics provisioned"

    az deployment group $command --name "ContainerAppsEnvironment" `
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --template-file "../Infrastructure/Templates/ContainerAppsEnvironment.json" `
        --parameters "../Infrastructure/Parameters/ContainerAppsEnvironment.parameters.json" `
        --parameters "ContainerAppsEnvironment_name=$($EnvironmentSettings.ContainerAppsEnvironmentName)" `
        --parameters "accountName=$($EnvironmentSettings.StorageAccountName)" `
        --parameters "workspaceName=$($EnvironmentSettings.LogAnalyticsName)" `
        --output none
    Write-Host "Container Apps Environment provisioned"

    az deployment group $command --name "ContainerRegistry" `
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --template-file "../Infrastructure/Templates/ContainerRegistry.json" `
        --parameters "../Infrastructure/Parameters/ContainerRegistry.parameters.json" `
        --output none
    Write-Host "Container Registry provisioned"

    $scope = az acr show --resource-group  $($EnvironmentSettings.ResourceGroupName) --name $($EnvironmentSettings.ContainerRegistryName) --query id -o tsv
    $upn = az containerapp env identity show --name $($EnvironmentSettings.ContainerAppsEnvironmentName) --resource-group $($EnvironmentSettings.ResourceGroupName) --query principalId -o tsv
    az role assignment $command --role "AcrPull" --assignee $upn --scope $scope --output none   

    ./Build-Containers.ps1 -Environment $Environment -AzureDeployment $true 

    $ContainerRegistryAddress = $($EnvironmentSettings.ContainerRegistryName).toLower()+".azurecr.io"
    az deployment group $command --name $($EnvironmentSettings.ContainerAppLLM) `
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --template-file "../Infrastructure/Templates/ContainerApp.json" `
        --parameters "../Infrastructure/Parameters/ContainerApp.$($EnvironmentSettings.ContainerAppLLM).parameters.json" `
        --parameters "containerapp_name=$($EnvironmentSettings.ContainerAppLLM)" `
        --parameters "managedenvironment_name=$($EnvironmentSettings.ContainerAppsEnvironmentName)" `
        --parameters "registry=$ContainerRegistryAddress" `
        --output none
    Write-Host "Ollama container app provisioned"

    az deployment group $command --name "ContainerApp" `
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --template-file "../Infrastructure/Templates/ContainerApp.json" `
        --parameters "../Infrastructure/Parameters/ContainerApp.$($EnvironmentSettings.ContainerAppGUI).parameters.json" `
        --parameters "containerapp_name=$($EnvironmentSettings.ContainerAppGUI)" `
        --parameters "managedenvironment_name=$($EnvironmentSettings.ContainerAppsEnvironmentName)" `
        --parameters "registry=$ContainerRegistryAddress" `
        --output none
    Write-Host "Ollama GUI container app provisioned"

    az deployment group $command --name $($EnvironmentSettings.ContainerChainlit)`
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --template-file "../Infrastructure/Templates/ContainerApp.json" `
        --parameters "../Infrastructure/Parameters/ContainerApp.$($EnvironmentSettings.ContainerChainlit).parameters.json" `
        --parameters "containerapp_name=$($EnvironmentSettings.ContainerChainlit)" `
        --parameters "managedenvironment_name=$($EnvironmentSettings.ContainerAppsEnvironmentName)" `
        --parameters "registry=$ContainerRegistryAddress" `
        --output none
    Write-Host "Chainlit container app provisioned"

    az deployment group $command --name $($EnvironmentSettings.ContainerAppProxy)`
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --template-file "../Infrastructure/Templates/ContainerApp.json" `
        --parameters "../Infrastructure/Parameters/ContainerApp.$($EnvironmentSettings.ContainerAppProxy).parameters.json" `
        --parameters "containerapp_name=$($EnvironmentSettings.ContainerAppProxy)" `
        --parameters "managedenvironment_name=$($EnvironmentSettings.ContainerAppsEnvironmentName)" `
        --parameters "registry=$ContainerRegistryAddress" `
        --output none

    $scope = az keyvault show --resource-group  $($EnvironmentSettings.ResourceGroupName) --name $($EnvironmentSettings.KeyVaultName) --query id -o tsv
    $upn = az containerapp identity show --name $($EnvironmentSettings.ContainerAppProxy) --resource-group $($EnvironmentSettings.ResourceGroupName) --query principalId -o tsv
    az role assignment $command --role  "Key Vault Secrets User" --assignee $upn --scope $scope --output none

    az containerapp secret set --name $($EnvironmentSettings.ContainerAppProxy) `
         --resource-group $($EnvironmentSettings.ResourceGroupName) `
         --secrets "user-key=keyvaultref:https://$($EnvironmentSettings.KeyVaultName).vault.azure.net/secrets/OLLAMA-ADMIN-KEY,identityref:system"  --output none        

    az containerapp secret set --name $($EnvironmentSettings.ContainerAppProxy) `
         --resource-group $($EnvironmentSettings.ResourceGroupName) `
         --secrets "admin-key=keyvaultref:https://$($EnvironmentSettings.KeyVaultName).vault.azure.net/secrets/OLLAMA-USER-KEY,identityref:system" --output none        

    Write-Host "Ollama proxy container app provisioned"

    az containerapp exec --name $($EnvironmentSettings.ContainerAppLLM) `
        --resource-group $($EnvironmentSettings.ResourceGroupName) `
        --command "ollama pull tinyllama:latest"  --output none
    Write-Host "Ollama pulled tinyllama:latest"

    $revision = az containerapp revision list `
         --name $($EnvironmentSettings.ContainerAppProxy) `
         --resource-group $($EnvironmentSettings.ResourceGroupName) --query "[].name" -o tsv

    az containerapp revision restart `
        --name $($EnvironmentSettings.ContainerAppProxy) `
        --resource-group $($EnvironmentSettings.ResourceGroupName) --revision  $revision  `
        --output none
    
    Write-Host "Ollama Proxy API Keys:"
    $requiredSecrets | ForEach-Object {
        Write-Host "$_ : $requiredSecrets[$_]"
    }
}
else
{
    Write-Host -ForegroundColor Red "../Configuration/$Environment.json not found."
}