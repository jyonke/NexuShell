function Get-NexusNugetRepository {
    <#
    .SYNOPSIS
    Returns info about configured NuGet repository
    
    .DESCRIPTION
    Returns details for currently configured NuGet repositories on your Nexus server
    
    .PARAMETER Type
    The type of repository to create: Hosted,Group,Proxy
    
    .PARAMETER Name
    Query for a specific repository by name
    
    .EXAMPLE
    Get-NexusNuGetRepository -Name nuget-group -Type Group
    
    .NOTES
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/Get-NexusNugetRepository/')]
    Param(
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

        $urislug = "/service/rest/v1/repositories/nuget/$Type/$Name"

    }

    process {   
        Invoke-Nexus -UriSlug $urislug -Method GET
    }
}