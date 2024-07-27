function New-NexusYumGroupRepository {
    <#
    .SYNOPSIS
    Creates a Yum Group repository
    
    .DESCRIPTION
    Creates a Yum Group repository
    
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

    .PARAMETER DeploymentPolicy
    Required by the API, but thrown away by the underlying system. Use whatever you want here from the set
    
    .PARAMETER ContentDisposition
    Add Content-Disposition header as 'Attachment' to disable some content from being inline in a browser

    .PARAMETER KeyPair
    PGP signing key pair (armored private key e.g. gpg --export-secret-key --armor )

    .PARAMETER Passphrase
    Passphrase used to create your private key
    
    .EXAMPLE
    New-NexusYumGroupRepository -Name Yum-group -GroupMembers YumProxy,MyYumRepo -DeploymentPolicy Allow
    
    .NOTES
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/New-NexusYumGroupRepository/')]
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
        $UseStrictContentTypeValidation,

        [Parameter(Mandatory)]
        [ValidateSet('Allow', 'Deny', 'Allow_Once')]
        [String]
        $DeploymentPolicy = 'Allow_Once',

        [Parameter(ParameterSetName = "YumSigning")]
        [string]
        $KeyPair,

        [Parameter(ParameterSetName = "YumSigning")]
        [string]
        $Passphrase
    )
    begin {

        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }

        $urislug = "/service/rest/v1/repositories/yum/group"

    }

    process {

        $body = @{
            name       = $Name
            online     = [bool]$Online
            storage    = @{
                blobStoreName               = $BlobStore
                strictContentTypeValidation = [bool]$UseStrictContentTypeValidation
                writePolicy                 = $DeploymentPolicy.ToLower()
            }
            group      = @{
                memberNames = $GroupMembers
            }
            yumSigning = @{
                keypair    = $KeyPair
                Passphrase = $Passphrase
            }
        }
        
        Write-Verbose $($Body | ConvertTo-Json)
        Invoke-Nexus -UriSlug $urislug -Body $Body -Method POST

    }

}