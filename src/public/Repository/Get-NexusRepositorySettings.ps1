function Get-NexusRepositorySettings {
    <#
    .SYNOPSIS
    Returns detailed settings information about configured repository
    
    .DESCRIPTION
    Returns details for currently configured repositoriy on your Nexus server
    
    .PARAMETER Format
    Query for only a specific repository format. E.g. nuget, maven2, or docker

    .PARAMETER Type
    The type of repository to query: Hosted,Group,Proxy
    
    .PARAMETER Name
    Query for a specific repository by name
    
    .EXAMPLE
    Get-NexusRepository -Format maven2 -Name maven-releases -Type Hosted
    
    .NOTES
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/Get-NexusRepositorySettings/')]
    Param(
        [Parameter(Mandatory)]
        [String]
        [ValidateSet('apt', 'bower', 'cocoapods', 'conan', 'conda', 'docker', 'gitlfs', 'go', 'helm', 'maven2', 'npm', 'nuget', 'p2', 'pypi', 'r', 'raw', 'rubygems', 'yum')]
        $Format,

        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter(Mandatory)]
        [ValidateSet('hosted', 'proxy', 'group')]
        [String]
        $Type
    )
    begin {

        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }
        # Update format string for proper API mapping
        switch ($Format) {
            maven2 { $FormatString = 'maven' }
            Default { $FormatString = $Format }
        }

        $urislug = "/service/rest/v1/repositories/$FormatString/$Type/$Name"

    }

    process {
        Write-Verbose $urislug   
        Invoke-Nexus -UriSlug $urislug -Method GET
    }
}