function Update-NexusDockerGroupRepository {
    <#
    .SYNOPSIS
    Updates properties of a given Docker group repository

    .PARAMETER Name
    The name of the Docker group repository to update

    .PARAMETER GroupMembers
    The Docker Repositories to add as group members

    .PARAMETER Online
    Indicates if the repository should be online

    .PARAMETER BlobStoreName
    The name of the blob store to use

    .PARAMETER UseStrictContentValidation
    Indicates if strict content type validation should be enforced

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
    Update-NexusDockerGroupRepository -Name DockerGroup -GroupMembers 'DockerHostedTest','DockerProxyTest'

    # Updates the specified Docker group repository with the provided parameters
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/Update-NexusDockerGroupRepository/', SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter(Mandatory)]
        [String[]]
        $GroupMembers,

        [Parameter()]
        [Switch]
        $Online,

        [Parameter()]
        [String]
        $BlobStore,

        [Parameter()]
        [Switch]
        $UseStrictContentTypeValidation,

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
        $urislug = "/service/rest/v1/repositories/docker/group/$Name"

        $Body = Get-NexusRepositorySettings -Format docker -Name $Name -Type group -ErrorAction 'Stop' | Select-Object -Property * -ExcludeProperty format, type | Convert-ObjectToHashtable

        $Modified = $false
        switch -Wildcard ($PSBoundParameters.Keys) {
            "Online" {
                if ($Body.online -ne $Online) {
                    $Body.online = [bool]$Online
                    $Modified = $true
                }
            }
            "BlobStoreName" {
                if ($Body.storage.blobStoreName -ne $BlobStoreName) {
                    $Body.storage.blobStoreName = $BlobStoreName
                    $Modified = $true
                }
            }
            "UseStrictContentValidation" {
                if ($Body.storage.strictContentTypeValidation -ne ([bool]::Parse($UseStrictContentValidation))) {
                    $Body.storage.strictContentTypeValidation = [bool]::Parse($UseStrictContentValidation)
                    $Modified = $true
                }
            }
            'GroupMembers' {
                if (Compare-Object -ReferenceObject $Body.group.membernames -DifferenceObject $GroupMembers) {
                    $Body.group.membernames = $GroupMembers
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
            if ($PSCmdlet.ShouldProcess($Name, "Update Docker Group Repository")) {
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
