param (
    [Parameter(Mandatory=$true)] [string]$DeploymentName="G-Template",
    [Parameter(Mandatory=$true)][string]$DSCBlobContext=""
 #   [Parameter(Mandatory=$true)][string]$RegistrationKey="",
 #   [Parameter(Mandatory=$true)][string]$AccountID=""
)

$ResourceGroupName=$DeploymentName + "-Auto"
#$AutomationAccountName="CapDemo-Auto"
$AutomationAccountName=$DeploymentName + "-Auto"
write-host "Collecting Automation Account Details.." -ForegroundColor Cyan -NoNewline
$Account = Get-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName
$RegistrationInfo = $Account | Get-AzureRmAutomationRegistrationInfo
$AccountDetails=get-azurermresource -ResourceName $account.AutomationAccountName -ResourceType "Microsoft.Automation/automationAccounts" -ResourceGroupName $resourcegroupname
Write-Host "..Done" -ForegroundColor Cyan
#.\azuredeploy.ps1 -DeploymentName CAPDemo -Regurl $RegistrationInfo.Endpoint  -RegistrationKey $RegistrationInfo.primarykey -AccountID $AccountDetails.resourceid 


new-azurermresourcegroup -name ($DeploymentName) -location "West US"

new-azurermresourcegroup -name ($DeploymentName + "-NET") -location "West US"

New-AzureRmResourceGroupDeployment -ResourceGroupName $DeploymentName -TemplateFile azuredeploy.json -TemplateParameterFile azuredeploy.parameters.json  -Regurl $RegistrationInfo.Endpoint  -RegistrationKey $RegistrationInfo.primarykey -AccountID $AccountDetails.resourceid -DSCBlobContext $DSCBlobContext
