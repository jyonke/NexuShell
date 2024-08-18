function New-NexusPyPiGroupRepository {
    <#
    .SYNOPSIS
    Creates a PyPi Group repository
    
    .DESCRIPTION
    Creates a PyPi Group repository
    
    .PARAMETER Name
    The name of the repository
    
    .PARAMETER GroupMembers
    The PyPi Repositories to add as group members
    
    .PARAMETER Online
    Marks the repository as online
    
    .PARAMETER BlobStore
    The blob store to attach to the repository
    
    .PARAMETER UseStrictContentTypeValidation
    Validate that all content uploaded to this repository is of a MIME type appropriate for the repository format

    
    .PARAMETER ContentDisposition
    Add Content-Disposition header as 'Attachment' to disable some content from being inline in a browser
    
    .EXAMPLE
    New-NexusPyPiGroupRepository -Name PyPi-group -GroupMembers PyPiProxy,MyPyPiRepo
    
    .NOTES
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/New-NexusPyPiGroupRepository/')]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter(Mandatory)]
        [String[]]
        $GroupMembers,

        [Parameter()]
        [Switch]
        $Online = $true,

        [Parameter()]
        [String]
        $BlobStore = 'default',

        [Parameter()]
        [Switch]
        $UseStrictContentTypeValidation
    )
    begin {

        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }

        $urislug = "/service/rest/v1/repositories/pypi/group"

    }

    process {

        $body = @{
            name    = $Name
            online  = [bool]$Online
            storage = @{
                blobStoreName               = $BlobStore
                strictContentTypeValidation = [bool]$UseStrictContentTypeValidation
            }
            group   = @{
                memberNames = $GroupMembers
            }
        }
        
        Write-Verbose $($Body | ConvertTo-Json)
        Invoke-Nexus -UriSlug $urislug -Body $Body -Method POST

    }

}