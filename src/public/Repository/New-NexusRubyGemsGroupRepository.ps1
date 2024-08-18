function New-NexusRubyGemsGroupRepository {
    <#
    .SYNOPSIS
    Creates a RubyGems Group repository
    
    .DESCRIPTION
    Creates a RubyGems Group repository
    
    .PARAMETER Name
    The name of the repository
    
    .PARAMETER GroupMembers
    The R Repositories to add as group members
    
    .PARAMETER Online
    Marks the repository as online
    
    .PARAMETER BlobStore
    The blob store to attach to the repository
    
    .PARAMETER UseStrictContentTypeValidation
    Validate that all content uploaded to this repository is of a MIME type appropriate for the repository format

    
    .PARAMETER ContentDisposition
    Add Content-Disposition header as 'Attachment' to disable some content from being inline in a browser
    
    .EXAMPLE
<<<<<<< HEAD
    New-NexusRubyGemsGroupRepository -Name RubyGems-group -GroupMembers RubyGemsProxy,MyRubyGemsRepo
=======
    New-NexusRubyGemsGroupRepository -Name R-group -GroupMembers RProxy,MyRRepo
>>>>>>> 453cfe2f0cd797dbf728c8aeebfde338b150e6c0
    
    .NOTES
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/New-NexusRubyGemsGroupRepository/')]
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

        $urislug = "/service/rest/v1/repositories/rubygems/group"

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