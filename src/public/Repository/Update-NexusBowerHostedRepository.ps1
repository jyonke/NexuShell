function Update-NexusBowerHostedRepository {
    <#
    .SYNOPSIS
    Updates properties of a given Bower hosted repository

    .PARAMETER Name
    The name of the Bower hosted repository to update

    .PARAMETER Type
    The type of repository: hosted, proxy, group

    .PARAMETER CleanupPolicy
    The names of the cleanup policies to apply

    .PARAMETER Online
    Indicates if the repository should be online

    .PARAMETER BlobStore
    The name of the blob store to use

    .PARAMETER UseStrictContentTypeValidation
    Indicates if strict content type validation should be enforced

    .PARAMETER DeploymentPolicy
    The write policy for the repository

    .PARAMETER HasProprietaryComponents
    Indicates if the repository should allow proprietary components

    .PARAMETER Force
    Don't prompt for confirmation before updating

    .NOTES
    This does not automatically migrate components from the previous settings.

    .EXAMPLE
    $RepoParams = @{
        Name = 'MyBowerRepo'
        CleanupPolicy = '30 Days'
        DeploymentPolicy = 'Allow'
        UseStrictContentTypeValidation = $false
    }
    
    Update-NexusBowerHostedRepository @RepoParams
    
    # Updates the specified Bower hosted repository with the provided parameters
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/Update-NexusBowerHostedRepository/', SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [string[]]
        $CleanupPolicy,

        [Parameter()]
        [switch]
        $Online,

        [Parameter()]
        [string]
        $BlobStore,

        [Parameter()]
        [Alias('StrictContentValidation')]
        [Switch]
        $UseStrictContentTypeValidation,

        [Parameter()]
        [ValidateSet('Allow', 'Deny', 'Allow_Once', 'Replication_Only')]
        [String]
        $DeploymentPolicy = 'Allow_Once',

        [Parameter()]
        [switch]
        $HasProprietaryComponents,

        [Parameter()]
        [Switch]
        $Force
    )
    begin {
        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }
        if ($Force -and -not $Confirm) {
            $ConfirmPreference = 'None'
        }
    }
    end {
        $urislug = "/service/rest/v1/repositories/bower/hosted/$Name"

        $Body = Get-NexusRepositorySettings -Format bower -Name $Name -Type hosted -ErrorAction 'Stop' | Select-Object -Property * -ExcludeProperty format, type | Convert-ObjectToHashtable

        $Modified = $false
        switch -Wildcard ($PSBoundParameters.Keys) {
            "Online" {
                if ($Body.online -ne $Online) {
                    $Body.online = [bool]$Online
                    $Modified = $true
                }
            }
            "BlobStoreName" {
                if ($Body.storage.blobStoreName -ne $BlobStore) {
                    $Body.storage.blobStoreName = $BlobStore
                    $Modified = $true
                }
            }
            "UseStrictContentTypeValidation" {
                if ([bool]$Body.storage.strictContentTypeValidation -ne [bool]$UseStrictContentTypeValidation) {
                    [bool]$Body.storage.strictContentTypeValidation = [bool]$UseStrictContentTypeValidation
                    $Modified = $true
                }
            }
            "DeploymentPolicy" {
                $deploymentPolicyMap = @{
                    "Allow"            = "ALLOW"
                    "Deny"             = "DENY"
                    "Allow_Once"       = "ALLOW_ONCE"
                    "Replication_Only" = "REPLICATION_ONLY"
                }
                if ($Body.storage.writePolicy -ne $deploymentPolicyMap[$DeploymentPolicy]) {
                    $Body.storage.writePolicy = $deploymentPolicyMap[$DeploymentPolicy]
                    $Modified = $true
                }
            }
            "CleanupPolicy" {
                if ($CleanupPolicy) {
                    $Body.cleanup.policyNames = $CleanupPolicy
                    $Modified = $true
                }
            }
            "HasProprietaryComponents" {
                if ($Body.component.proprietaryComponents -ne $HasProprietaryComponents.IsPresent) {
                    $Body.component.proprietaryComponents = $HasProprietaryComponents.IsPresent
                    $Modified = $true
                }
            }
        }

        if ($Modified) {
            if ($PSCmdlet.ShouldProcess($Name, "Update Bower Hosted Repository")) {
                Write-Verbose $($Body | ConvertTo-Json)
                Invoke-Nexus -UriSlug $urislug -Method Put -Body $Body
            }
        }
        else {
            Write-Verbose "No change to '$($Name)' was required."
        }
    }
}
