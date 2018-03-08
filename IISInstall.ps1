configuration IISInstall
{
    Node G-Win2016-DC
    {
        WindowsFeature IIS
        {
            Ensure               = 'Present'
            Name                 = 'Web-Server'
            IncludeAllSubFeature = $true

        }
    }

}