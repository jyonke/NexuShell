function New-NexusMavenHostedRepository {
    <#
    .SYNOPSIS
    Creates a new Maven Hosted repository
    
    .DESCRIPTION
    Creates a new Maven Hosted repository
    
    .PARAMETER Name
    The name of the repository
    
    .PARAMETER CleanupPolicy
    The Cleanup Policies to apply to the repository
       
    .PARAMETER Online
    Marks the repository to accept incoming requests
    
    .PARAMETER BlobStoreName
    Blob store to use to store Maven packages
    
    .PARAMETER UseStrictContentTypeValidation
    Validate that all content uploaded to this repository is of a MIME type appropriate for the repository format
    
    .PARAMETER DeploymentPolicy
    Controls if deployments of and updates to artifacts are allowed
    
    .PARAMETER HasProprietaryComponents
    Components in this repository count as proprietary for namespace conflict attacks (requires Sonatype Nexus Firewall)

    .PARAMETER VersionPolicy
    What type of artifacts does this repository store? Defaults to Release

    .PARAMETER LayoutPolicy
    Validate that all paths are maven artifact or metadata paths. Defaults to Strict.

    .PARAMETER ContentDisposition
    Add Content-Disposition header as 'Attachment' to disable some content from being inline in a browser. Defaults to Inline.
    
    .EXAMPLE
    New-NexusMavenHostedRepository -Name MavenHostedTest -DeploymentPolicy Allow

    .EXAMPLE

    $RepoParams = @{
        Name = 'MyMavenRepo'
        CleanupPolicy = '90 Days'
        DeploymentPolicy = 'Allow'
        UseStrictContentTypeValidation = $true
        VersionPolicy = 'Release'
        LayoutPolicy = 'Strict'
        ContentDisposition = 'Attachment'
    }
    
    New-NexusMavenHostedRepository @RepoParams

    .NOTES
    General notes
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/New-NexusMavenHostedRepository/')]
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
        [ValidateSet('Allow', 'Deny', 'Allow_Once')]
        [String]
        $DeploymentPolicy,

        [Parameter()]
        [Switch]
        $HasProprietaryComponents,

        [Parameter()]
        [ValidateSet('Release', 'Snapshot', 'Mixed')]
        [String]
        $VersionPolicy = 'Release',

        [Parameter()]
        [ValidateSet('Strict', 'Permissive')]
        [String]
        $LayoutPolicy = 'Strict',

        [Parameter()]
        [ValidateSet('Inline', 'Attachment')]
        [String]
        $ContentDisposition = 'Inline'
    )

    begin {

        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }

        $urislug = "/service/rest/v1/repositories"

    }

    process {
        $formatUrl = $urislug + '/maven'

        $FullUrlSlug = $formatUrl + '/hosted'


        $body = @{
            name    = $Name
            online  = [bool]$Online
            storage = @{
                blobStoreName               = $BlobStoreName
                strictContentTypeValidation = [bool]$UseStrictContentTypeValidation
                writePolicy                 = $DeploymentPolicy
            }
            cleanup = @{
                policyNames = @($CleanupPolicy)
            }
            maven   = @{
                versionPolicy      = $VersionPolicy
                layoutPolicy       = $LayoutPolicy
                contentDisposition = $ContentDisposition
            }
        }

        if ($HasProprietaryComponents) {
            $Prop = @{
                proprietaryComponents = 'True'
            }
    
            $Body.Add('component', $Prop)
        }

        Write-Verbose $($Body | ConvertTo-Json)
        Invoke-Nexus -UriSlug $FullUrlSlug -Body $Body -Method POST

    }
}