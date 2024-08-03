function Update-NexusAptHostedRepository {
    <#
    .SYNOPSIS
    Updates properties of a given Apt hosted repository

    .PARAMETER Name
    The name of the Apt hosted repository to update

    .PARAMETER Distribution
    Distribution to fetch e.g. bionic
    
    .PARAMETER SigningKey
    PGP signing key pair (armored private key e.g. gpg --export-secret-key --armor )
    
    .PARAMETER SigningKeyPassphrase
    Passphrase to access PGP Signing Key

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
        Name = 'AptPackages'
        Distribution = 'bookworm'
        SigningKey = 'NewSuperSecretString'
        DeploymentPolicy = 'Allow_Once'
    }
    
    Update-NexusAptHostedRepository @RepoParams


    # Updates the specified Apt hosted repository with the provided parameters
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/Update-NexusAptHostedRepository/', SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [String]
        $Distribution,

        [Parameter(Mandatory)]
        [String]
        $SigningKey,

        [Parameter()]
        [String]
        $SigningKeyPassphrase,

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
        [ValidateSet('Allow', 'Deny', 'Allow_Once')]
        [string]
        $DeploymentPolicy,

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
        $urislug = "/service/rest/v1/repositories/apt/hosted/$Name"

        $Body = Get-NexusRepositorySettings -Format apt -Name $Name -Type hosted -ErrorAction 'Stop' | Select-Object -Property * -ExcludeProperty format, type | Convert-ObjectToHashtable

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
            "Distribution" {
                if ($Body.apt.distribution -ne $Distribution) {
                    $Body.apt.distribution = $Distribution
                    $Modified = $true
                }
            }
            "SigningKey" {
                $Body.aptSigning = @{
                    keypair    = $SigningKey
                    passphrase = ''
                }
                $Modified = $true
            }
            "SigningKeyPassphrase" {
                $Body.aptSigning.passphrase = $SigningKeyPassphrase
                $Modified = $true
            }
        }

        if ($Modified) {
            if ($PSCmdlet.ShouldProcess($Name, "Update Apt Hosted Repository")) {
                Write-Verbose $($Body | ConvertTo-Json)
                Invoke-Nexus -UriSlug $urislug -Method Put -Body $Body
            }
        }
        else {
            Write-Verbose "No change to '$($Name)' was required."
        }
    }
}
