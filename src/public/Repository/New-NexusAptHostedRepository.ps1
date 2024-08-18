function New-NexusAptHostedRepository {
    <#
    .SYNOPSIS
    Creates a new Hosted Apt repository
    
    .DESCRIPTION
    Creates a new Hosted Apt repository
    
    .PARAMETER Name
    The name given to the repository
    
    .PARAMETER Distribution
    Distribution to fetch e.g. bionic
    
    .PARAMETER SigningKey
    PGP signing key pair (armored private key e.g. gpg --export-secret-key --armor )
    
    .PARAMETER SigningKeyPassphrase
    Passphrase to access PGP Signing Key
    
    .PARAMETER BlobStore
    Blob store used to store repository contents
    
    .PARAMETER UseStrictContentTypeValidation
    Validate that all content uploaded to this repository is of a MIME type appropriate for the repository format

    .PARAMETER DeploymentPolicy
    Controls if deployments of and updates to artifacts are allowed
    
    .PARAMETER CleanupPolicy
    Components that match any of the Applied policies will be deleted
    
    .PARAMETER Online
    The repository accepts incoming requests
    
    .PARAMETER HasProprietaryComponents
    Components in this repository count as proprietary for namespace conflict attacks (requires Sonatype Nexus Firewall)
    
    .EXAMPLE
    $RepoParams = @{
        Name = 'AptPackages'
        Distribution = 'bionic'
        SigningKey = 'SuperSecretString'
        DeploymentPolicy = 'Allow_Once'
    }
    
    New-NexusAptHostedRepository @RepoParams

    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/New-NexusAptHostedRepository/')]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter(Mandatory)]
        [String]
        $Distribution,

        [Parameter(Mandatory)]
        [String]
        $SigningKey,

        [Parameter()]
        [String]
        $SigningKeyPassphrase,

        [Parameter()]
        [String]
        $BlobStore = 'default',

        [Parameter()]
        [Alias('StrictContentValidation')]
        [Switch]
        $UseStrictContentTypeValidation,

        [Parameter()]
        [ValidateSet('Allow', 'Deny', 'Allow_Once', 'Replication_Only')]
        [String]
        $DeploymentPolicy = 'Allow_Once',

        [Parameter()]
        [String]
        $CleanupPolicy,

        [Parameter()]
        [Switch]
        $Online = $true,

        [Parameter()]
        [Switch]
        $HasProprietaryComponents
    )

    begin {
        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }

        $urislug = "/service/rest/v1/repositories/apt/hosted"
    }
    process {
        $Body = @{
            name       = $Name
            online     = [bool]$Online
            apt        = @{
                distribution = $Distribution
            }
            aptSigning = @{
                keypair    = $SigningKey
                passprhase = $SigningKeyPassphrase
            }
            cleanup    = @{
                policyNames = @($CleanupPolicy )
            }
            storage    = @{
                strictContentTypeValidation = [bool]$UseStrictContentTypeValidation
                blobStoreName               = $BlobStore
                writePolicy                 = $($DeploymentPolicy.ToUpper())
            }
            component  = @{
                proprietaryComponents = [bool]$HasProprietaryComponents
            }
        }

        Write-Verbose $($Body | ConvertTo-Json)
        Invoke-Nexus -UriSlug $urislug -Body $Body -Method POST

    }
}