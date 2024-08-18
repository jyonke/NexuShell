function Update-NexusDockerHostedRepository {
    <#
    .SYNOPSIS
    Updates properties of a given Docker hosted repository

    .PARAMETER Name
    The name of the Docker hosted repository to update

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

    .PARAMETER EnableV1
    Whether to allow clients to use the V1 API to interact with this repository

    .PARAMETER ForceBasicAuth
    Whether to force authentication (Docker Bearer Token Realm required if false)
    
    .PARAMETER HttpPort
    Create an HTTP connector at specified port
    
    .PARAMETER HttpsPort
    Create an HTTPS connector at specified port

    .PARAMETER Force
    Don't prompt for confirmation before updating

    .NOTES
    This does not automatically migrate components from the previous settings.

    .EXAMPLE
    Update-NexusDockerHostedRepository -Name DockerHostedTest -BlobStoreName default

    # Updates the specified Docker hosted repository with the provided parameters
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/Update-NexusDockerHostedRepository/', SupportsShouldProcess, ConfirmImpact = 'High')]
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
        [ValidateSet('True', 'False')]
        [string]
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
        $EnableV1,

        [Parameter()]
        [Switch]
        $ForceBasicAuth,

        [Parameter()]
        [String]
        $HttpPort,
        
        [Parameter()]
        [String]
        $HttpsPort,

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
        $urislug = "/service/rest/v1/repositories/docker/hosted/$Name"

        $Body = Get-NexusRepositorySettings -Format docker -Name $Name -Type hosted -ErrorAction 'Stop' | Select-Object -Property * -ExcludeProperty format, type | Convert-ObjectToHashtable

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
                if ($Body.storage.strictContentTypeValidation -ne ([bool]::Parse($UseStrictContentTypeValidation))) {
                    $Body.storage.strictContentTypeValidation = [bool]::Parse($UseStrictContentTypeValidation)
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
            'EnableV1' {
                if ($Body.docker.v1Enabled -ne $EnableV1.IsPresent) {
                    $Body.docker.v1Enabled = $EnableV1.IsPresent
                    $Modified = $true
                }
            }
            'ForceBasicAuth' {
                if ($Body.docker.forceBasicAuth -ne $ForceBasicAuth.IsPresent) {
                    $Body.docker.forceBasicAuth = $ForceBasicAuth.IsPresent
                    $Modified = $true
                }
            }
            'HttpPort' {
                if ($Body.docker.httpPort -ne $HttpPort) {
                    $Body.docker.httpPort = $HttpPort
                    $Modified = $true
                }
            }
            'HttpsPort' {
                if ($Body.docker.httpsPort -ne $HttpsPort) {
                    $Body.docker.httpsPort = $HttpsPort
                    $Modified = $true
                }
            }
        }

        if ($Modified) {
            if ($PSCmdlet.ShouldProcess($Name, "Update Docker Hosted Repository")) {
                Write-Verbose $($Body | ConvertTo-Json)
                Invoke-Nexus -UriSlug $urislug -Method Put -Body $Body

                if ($ForceBasicAuth -eq $false) {
                    Write-Warning "Docker Bearer Token Realm required since -ForceBasicAuth was not passed."
                    Write-Warning "Use Add-NexusRealm to enable if desired."
                }
            }
        }
        else {
            Write-Verbose "No change to '$($Name)' was required."
        }
    }
}
