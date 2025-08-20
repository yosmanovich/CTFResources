param(
    [Parameter()]    
    [ValidateSet('Dev','Test','Staging','Prod')]
    [string]$Environment = "Dev",
    [switch]$AzureDeployment = $false

)

if (Test-Path -Path "../Configuration/$Environment.json")
{
    $EnvironmentSettings = (Get-Content "../Configuration/$Environment.json" -Raw) | ConvertFrom-Json
    
    $ContainerRegistryAddress = $($EnvironmentSettings.ContainerRegistryName).toLower()+".azurecr.io"
    "acrName=$ContainerRegistryAddress" | Out-File -FilePath "..\Containers\.env"

    docker compose -f ../Containers/docker-compose.yaml up -d --build 
    if ($AzureDeployment -eq $true)
    {
        az acr login --name $ContainerRegistryAddress
        docker push $ContainerRegistryAddress/ollama:ollama
        docker push $ContainerRegistryAddress/ollama-proxy:ollama-proxy
        docker push $ContainerRegistryAddress/chainlit:chainlit    
        docker push $ContainerRegistryAddress/ollama-gui:ollama-gui
    }    
}