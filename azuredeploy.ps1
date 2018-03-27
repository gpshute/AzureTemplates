param (
    [Parameter(Mandatory=$true)][string]$DeploymentName="G-Template",
    [Parameter(Mandatory=$true)][string]$Regurl="",
    [Parameter(Mandatory=$true)][string]$RegistrationKey="",
    [Parameter(Mandatory=$true)][string]$AccountID=""
)


#.\azuredeploy.ps1 -DeploymentName CAPDemo -Regurl $RegistrationInfo.Endpoint  -RegistrationKey $RegistrationInfo.primarykey -AccountID $AccountDetails.resourceid 


new-azurermresourcegroup -name ($DeploymentName) -location "West US"

new-azurermresourcegroup -name ($DeploymentName + "-NET") -location "West US"

New-AzureRmResourceGroupDeployment -ResourceGroupName $DeploymentName -TemplateFile azuredeploy.json -TemplateParameterFile azuredeploy.parameters.json  -Regurl $RegistrationInfo.Endpoint  -RegistrationKey $RegistrationInfo.primarykey -AccountID $AccountDetails.resourceid 