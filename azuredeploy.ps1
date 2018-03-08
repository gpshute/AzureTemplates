param (
    [Parameter(Mandatory=$true)][string]$DeploymentName="G-Template"
)

new-azurermresourcegroup -name ($DeploymentName) -location "West US"

new-azurermresourcegroup -name ($DeploymentName + "-NET") -location "West US"

New-AzureRmResourceGroupDeployment -ResourceGroupName $DeploymentName -TemplateFile azuredeploy.json -TemplateParameterFile azuredeploy.parameters.json