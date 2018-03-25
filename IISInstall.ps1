configuration IISInstall
{
    Node CapGeminiDemoIISInstall
    {
        WindowsFeature IIS
        {
            Ensure               = 'Present'
            Name                 = 'Web-Server'
            IncludeAllSubFeature = $true

        }
    }

}