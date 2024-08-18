function New-NexusYumHostedRepository {
    <#
.SYNOPSIS
    Creates a new Yum Hosted repository
    
    .DESCRIPTION
    Creates a new Yum Hosted repository
    
    .PARAMETER Name
    The name of the repository
    
    .PARAMETER CleanupPolicy
    The Cleanup Policies to apply to the repository
    
    .PARAMETER Online
    Marks the repository to accept incoming requests
    
    .PARAMETER BlobStoreName
    Blob store to use to store R packages
    
    .PARAMETER UseStrictContentTypeValidation
    Validate that all content uploaded to this repository is of a MIME type appropriate for the repository format
    
    .PARAMETER DeploymentPolicy
    Controls if deployments of and updates to artifacts are allowed
    
    .PARAMETER HasProprietaryComponents
    Components in this repository count as proprietary for namespace conflict attacks (requires Sonatype Nexus Firewall)

    .PARAMETER RepoDataDepth
    Specifies the repository depth where repodata folder(s) are created

    .PARAMETER LayoutPolicy
    Validate that all paths are RPMs or yum metadata

    .EXAMPLE
    New-NexusYumHostedRepository -Name YumHostedTest -DeploymentPolicy Allow -RepoDataDepth 5

    .EXAMPLE

    $RepoParams = @{
        Name = 'MyYumRepo'
        CleanupPolicy = '90 Days'
        DeploymentPolicy = 'Allow'
        UseStrictContentTypeValidation = $true
        RepoDataDepth = 3
    }
    
    New-NexusYumHostedRepository @RepoParams

    .NOTES
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/New-NexusYumHostedRepository/')]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $CleanupPolicy,

        [Parameter()]
        [Switch]
        $Online = $true,

        [Parameter()]
        [String]
        $BlobStoreName = 'default',

        [Parameter()]
        [Alias('StrictContentValidation')]
        [Switch]
        $UseStrictContentTypeValidation,

        [Parameter()]
        [ValidateSet('Allow', 'Deny', 'Allow_Once', 'Replication_Only')]
        [String]
        $DeploymentPolicy = 'Allow_Once',

        [Parameter()]
        [Switch]
        $HasProprietaryComponents,

        [Parameter(Mandatory)]
        [ValidateRange(0, 5)]
        [int]
        $RepoDataDepth,

        [Parameter()]
        [ValidateSet('Strict', 'Permissive')]
        [String]
        $LayoutPolicy = 'Strict'
    )
    
    begin {

        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }

        $urislug = "/service/rest/v1/repositories/yum/hosted"

    }

    process {
        $body = @{
            name    = $Name
            online  = [bool]$Online
            storage = @{
                blobStoreName               = $BlobStoreName
                strictContentTypeValidation = [bool]$UseStrictContentTypeValidation
                writePolicy                 = $($DeploymentPolicy.ToUpper())
            }
            cleanup = @{
                policyNames = @($CleanupPolicy)
            }
            yum     = @{
                repodataDepth = $RepoDataDepth
                deployPolicy  = $LayoutPolicy
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