function New-NexusPyPiHostedRepository {
    <#
.SYNOPSIS
    Creates a new PyPi Hosted repository
    
    .DESCRIPTION
    Creates a new PyPi Hosted repository
    
    .PARAMETER Name
    The name of the repository
    
    .PARAMETER CleanupPolicy
    The Cleanup Policies to apply to the repository
    
    .PARAMETER Online
    Marks the repository to accept incoming requests
    
    .PARAMETER BlobStoreName
    Blob store to use to store PyPi packages
    
<<<<<<< HEAD
    .PARAMETER UseStrictContentTypeValidation
=======
    .PARAMETER StrictContentValidation
>>>>>>> 453cfe2f0cd797dbf728c8aeebfde338b150e6c0
    Validate that all content uploaded to this repository is of a MIME type appropriate for the repository format
    
    .PARAMETER DeploymentPolicy
    Controls if deployments of and updates to artifacts are allowed
    
    .PARAMETER HasProprietaryComponents
    Components in this repository count as proprietary for namespace conflict attacks (requires Sonatype Nexus Firewall)
    
    .EXAMPLE
    New-NexusPyPiHostedRepository -Name PyPiHostedTest -DeploymentPolicy Allow

    .EXAMPLE

    $RepoParams = @{
        Name = 'MyPyPiRepo'
        CleanupPolicy = '90 Days'
        DeploymentPolicy = 'Allow'
<<<<<<< HEAD
        UseStrictContentTypeValidation = $true
=======
        UseStrictContentValidation = $true
>>>>>>> 453cfe2f0cd797dbf728c8aeebfde338b150e6c0
    }
    
    New-NexusPyPiHostedRepository @RepoParams

    .NOTES
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/New-NexusPyPiHostedRepository/')]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $CleanupPolicy,

        [Parameter()]
        [Switch]
        $Online,

        [Parameter()]
        [String]
        $BlobStoreName = 'default',

        [Parameter()]
<<<<<<< HEAD
        [Alias('StrictContentValidation')]
        [Switch]
        $UseStrictContentTypeValidation,
=======
        [Switch]
        $UseStrictContentValidation,
>>>>>>> 453cfe2f0cd797dbf728c8aeebfde338b150e6c0

        [Parameter()]
        [ValidateSet('Allow', 'Deny', 'Allow_Once')]
        [String]
        $DeploymentPolicy,

        [Parameter()]
        [Switch]
        $HasProprietaryComponents
    )
    
    begin {

        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }

        $urislug = "/service/rest/v1/repositories/pypi/hosted"

    }

    process {
        $body = @{
            name    = $Name
            online  = [bool]$Online
            storage = @{
                blobStoreName               = $BlobStoreName
<<<<<<< HEAD
                strictContentTypeValidation = [bool]$UseStrictContentTypeValidation
=======
                strictContentTypeValidation = [bool]$UseStrictContentValidation
>>>>>>> 453cfe2f0cd797dbf728c8aeebfde338b150e6c0
                writePolicy                 = $DeploymentPolicy
            }
            cleanup = @{
                policyNames = @($CleanupPolicy)
            }
        }

        if ($HasProprietaryComponents) {
            $Prop = @{
                proprietaryComponents = 'True'
            }
    
            $Body.Add('component', $Prop)
        }

        Write-Verbose $($Body | ConvertTo-Json)
        Invoke-Nexus -UriSlug $urislug -Body $Body -Method POST
    }
}