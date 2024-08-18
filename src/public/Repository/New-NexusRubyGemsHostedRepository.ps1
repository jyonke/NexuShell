function New-NexusRubyGemsHostedRepository {
    <#
.SYNOPSIS
    Creates a new RubyGems Hosted repository
    
    .DESCRIPTION
    Creates a new RubyGems Hosted repository
    
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
    
    .EXAMPLE
    New-NexusRubyGemsHostedRepository -Name RubyGemsHostedTest -DeploymentPolicy Allow

    .EXAMPLE

    $RepoParams = @{
        Name = 'MyRubyGemsRepo'
        CleanupPolicy = '90 Days'
        DeploymentPolicy = 'Allow'
        UseStrictContentTypeValidation = $true
    }
    
    New-NexusRubyGemsHostedRepository @RepoParams

    .NOTES
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/New-NexusRubyGemsHostedRepository/')]
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
        $HasProprietaryComponents
    )
    
    begin {

        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }

        $urislug = "/service/rest/v1/repositories/rubygems/hosted"

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