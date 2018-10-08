param (
    [Parameter(Mandatory=$true)] [string]$DeploymentName="G-Template"
 )


write-host "Establishing Automation Environment" -ForegroundColor Cyan

$AutomationAccountName=$DeploymentName + "-Auto"
$ResourceGroupName=$DeploymentName + "-Auto"
$pattern = '[^a-zA-Z]'
$StorageAccountName=$ResourceGroupName.ToLower() + (get-random -Maximum 100000000)
$StorageAccountName -replace $pattern, '' 
$StorageAccountName=$StorageAccountname.Replace("-","").tolower()
$StorageAccountName=$StorageAccountname.Replace("_","").tolower()

write-host "Creating resource group" $ResourceGroupName ".." -ForegroundColor Cyan -NoNewline
$NewResourceGroup=New-AzureRmResourceGroup -name $ResourceGroupName -location "eastus2"
write-host "..Done" -ForegroundColor Cyan

write-host "Creating Automation Account.." $ResourceGroupName ".." -ForegroundColor Cyan -NoNewline
$NewAutomationAccount=New-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -Location "eastus2"
write-host "..Done" -ForegroundColor Cyan

write-host "Creating Storage Account.." $StorageAccountName ".." -ForegroundColor Cyan -NoNewline 
# Create a new azure storage account.
if (Get-AzureRmStorageAccountNameAvailability $StorageAccountName)
{
    #create the storage account
  $myStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location "eastus2" -SkuName Standard_LRS
}
write-host "..Done" -ForegroundColor Cyan

$storagekey=Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName 

$DSCstoragecontext=New-AzureStorageContext -StorageAccountName  $StorageAccountName -StorageAccountKey $storagekey.value[0]
$NewContainer=New-AzureStorageContainer -Name "automation" -Context $DSCstoragecontext -Permission Blob 

$UploadBlob1=Set-AzureStorageBlobContent -File ".\UpdateLCMforAAPull.zip" -Blob "UpdateLCMforAAPull.zip" -Context $DSCstoragecontext -Container "automation"
$DSCURL=($DSCstoragecontext.BlobEndPoint + "automation/UpdateLCMforAAPull.zip")
$UploadBloc2=Set-AzureStorageBlobContent -File "C:\Users\gshute\Documents\azure\Github\Templates\xWebadministration.zip" -Blob "xWebadministration.zip" -Context $DSCstoragecontext -Container "automation"

write-host "Importing DSC Module" -NoNewline -ForegroundColor Cyan

$NewModule=New-AzureRmAutomationModule -Name xWebAdministration -ContentLinkUri ($DSCstoragecontext.BlobEndPoint + "automation/xWebadministration.zip") -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
while($NewModule.ProvisioningState -ne "Succeeded")
{
    $NewModule = $NewModule | Get-AzureRmAutomationModule
    Start-Sleep -Seconds 3
    Write-Host "." -NoNewline -ForegroundColor Cyan
}
Write-Host ".Done" -ForegroundColor Cyan

$ImportModule=Import-AzureRmAutomationDscConfiguration -ResourceGroupName $ResourceGroupName -SourcePath "C:\Users\gshute\Documents\Azure\Github\Templates\IIsInstall.ps1"  -AutomationAccountName $AutomationAccountName  -Published

$CompilationJob = Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ConfigurationName "IIsInstall"
write-host "Compiling DSC Job" -NoNewline -ForegroundColor Cyan
while($CompilationJob.EndTime -eq $null -and $CompilationJob.Exception -eq $null)
{
    $CompilationJob = $CompilationJob | Get-AzureRmAutomationDscCompilationJob
    Start-Sleep -Seconds 3
    Write-Host "." -NoNewline -ForegroundColor Cyan
}
Write-Host ".Done" -ForegroundColor Cyan

$CompilationJob | Get-AzureRmAutomationDscCompilationJobOutput -Stream Any

Write-Host $DSCURL    
.\azuredeploy.ps1 -DeploymentName $DeploymentName -DSCBlobContext $DSCURL


#.\azuredeploy.ps1 -DeploymentName CAPDemo -Regurl $RegistrationInfo.Endpoint  -RegistrationKey $RegistrationInfo.primarykey -AccountID $AccountDetails.resourceid -DSCBlobContext $UploadBlob1.context.BlobEndPoint + "automation/UpdateLCMforAAPull.zip"
#.\azuredeploy.ps1 -DeploymentName CAPDemo  

