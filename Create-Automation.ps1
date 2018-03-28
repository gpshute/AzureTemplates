write-host "Establishing Automation Environment" -ForegroundColor Cyan

$AutomationAccountName="G-AutomationAccount-2"
$ResourceGroupName="G-Automation-2"
$pattern = '[^a-zA-Z]'
$StorageAccountName=$ResourceGroupName.ToLower() + (get-random -Maximum 100000000)
$StorageAccountName -replace $pattern, '' 
$StorageAccountName= $StorageAccountname.Replace("-","").tolower()
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




$storagecontext=New-AzureStorageContext -StorageAccountName  $StorageAccountName -StorageAccountKey $storagekey.value[0]
$NewContainer=New-AzureStorageContainer -Name "automation" -Context $storagecontext -Permission Blob 

$UploadBlob1=Set-AzureStorageBlobContent -File "C:\Users\gshute\Documents\azure\Github\Templates\UpdateLCMforAAPull.zip" -Blob "UpdateLCMforAAPull.zip" -Context $storagecontext -Container "automation"
$UploadBloc2=Set-AzureStorageBlobContent -File "C:\Users\gshute\Documents\azure\Github\Templates\xWebadministration.zip" -Blob "xWebadministration.zip" -Context $storagecontext -Container "automation"

write-host "Importing DSC Module" -NoNewline -ForegroundColor Cyan

$NewModule=New-AzureRmAutomationModule -Name xWebAdministration -ContentLinkUri ($storagecontext.BlobEndPoint + "automation/xWebadministration.zip") -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
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
write-host "Collecting Automation Account Details.." -ForegroundColor Cyan -NoNewline
$Account = Get-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName
$RegistrationInfo = $Account | Get-AzureRmAutomationRegistrationInfo
$AccountDetails=get-azurermresource -ResourceName $account.AutomationAccountName -ResourceType "Microsoft.Automation/automationAccounts" -ResourceGroupName $resourcegroupname
Write-Host "..Done" -ForegroundColor Cyan
    

#.\azuredeploy.ps1 -DeploymentName CAPDemo -Regurl $RegistrationInfo.Endpoint  -RegistrationKey $RegistrationInfo.primarykey -AccountID $AccountDetails.resourceid 

