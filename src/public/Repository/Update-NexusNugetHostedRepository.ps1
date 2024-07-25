function Update-NexusNugetHostedRepository {
    <#
    .SYNOPSIS
    Updates properties of a given NuGet hosted repository

    .PARAMETER Name
    The name of the NuGet hosted repository to update

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

    .NOTES
    This does not automatically migrate components from the previous settings.

    .EXAMPLE
    Update-NexusNugetHostedRepository -Name internal -BlobStoreName default

    # Updates the specified NuGet hosted repository with the provided parameters
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/Update-NexusNugetHostedRepository/', SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $CleanupPolicy,

        [Parameter()]
        [switch]
        $Online,

        [Parameter()]
        [string]
        $BlobStore,

        [Parameter()]
        [ValidateSet('True', 'False')]
        [string]
        $UseStrictContentTypeValidation,

        [Parameter()]
        [ValidateSet('Allow', 'Deny', 'Allow_Once')]
        [string]
        $DeploymentPolicy,

        [Parameter()]
        [switch]
        $HasProprietaryComponents
    )
    begin {
        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }
    }
    end {
        $urislug = "/service/rest/v1/repositories/nuget/hosted/$Name"

        $Body = Get-NexusNugetRepository -Name $Name -Type hosted -ErrorAction 'Stop' | Select-Object -Property * -ExcludeProperty format, type | Convert-ObjectToHashtable

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
            "UseStrictContentValidation" {
                if ($Body.storage.strictContentTypeValidation -ne ([bool]::Parse($UseStrictContentTypeValidation))) {
                    $Body.storage.strictContentTypeValidation = [bool]::Parse($UseStrictContentTypeValidation)
                    $Modified = $true
                }
            }
            "DeploymentPolicy" {
                $deploymentPolicyMap = @{
                    "Allow"      = "allow"
                    "Deny"       = "deny"
                    "Allow_Once" = "allow_once"
                }
                if ($Body.storage.writePolicy -ne $deploymentPolicyMap[$DeploymentPolicy]) {
                    $Body.storage.writePolicy = $deploymentPolicyMap[$DeploymentPolicy]
                    $Modified = $true
                }
            }
            "CleanupPolicy" {
                if ($Body.cleanup.policyNames -ne @($CleanupPolicy)) {
                    $Body.cleanup.policyNames = @($CleanupPolicy)
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
            if ($PSCmdlet.ShouldProcess($Name, "Update NuGet Hosted Repository")) {
                Write-Verbose $($Body | ConvertTo-Json)
                Invoke-Nexus -UriSlug $urislug -Method Put -Body $Body
            }
        }
        else {
            Write-Verbose "No change to '$($Name)' was required."
        }
    }
}
