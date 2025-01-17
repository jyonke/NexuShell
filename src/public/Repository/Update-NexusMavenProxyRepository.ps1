function Update-NexusMavenProxyRepository {
    <#
.SYNOPSIS
Creates a new Maven Proxy Repository

.DESCRIPTION
Creates a new Maven Proxy Repository

.PARAMETER Name
The name to give the repository

.PARAMETER ProxyRemoteUrl
Location of the remote repository being proxied, e.g. https://api.Maven.org/v3/index.json

.PARAMETER ContentMaxAgeMinutes
Time before cached content is refreshed. Defaults to 1440

.PARAMETER MetadataMaxAgeMinutes
Time before cached metadata is refreshed. Defaults to 1440

.PARAMETER UseNegativeCache
Use the built-in Negative Cache feature

.PARAMETER NegativeCacheTTLMinutes
The Negative Cache Time To Live value. Defaults to 1440

.PARAMETER CleanupPolicy
The Cleanup Policy to apply to this repository

.PARAMETER RoutingRule
Routing Rules you wish to apply to this repository

.PARAMETER Online
Mark the repository as Online. Defaults to True

.PARAMETER BlobStoreName
The back-end blob store in which to store cached packages

.PARAMETER UseStrictContentTypeValidation
Validate that all content uploaded to this repository is of a MIME type appropriate for the repository format

.PARAMETER UseNexusTrustStore
Use certificates stored in the Nexus truststore to connect to external systems

.PARAMETER UseAuthentication
Use authentication for the upstream repository

.PARAMETER AuthenticationType
The type of authentication required by the upstream repository

.PARAMETER Credential
Credentials to use to connecto to upstream repository

.PARAMETER HostnameFqdn
If using NTLM authentication, the Hostname of the NTLM host to query

.PARAMETER DomainName
The domain name of the NTLM host

.PARAMETER BlockOutboundConnections
Block outbound connections on the repository

.PARAMETER EnableAutoBlocking
Auto-block outbound connections on the repository if remote peer is detected as unreachable/unresponsive

.PARAMETER ConnectionRetries
Connection attempts to upstream repository before a failure

.PARAMETER ConnectionTimeoutSeconds
Amount of time to wait before retrying the connection to the upstream repository

.PARAMETER EnableCircularRedirects
Enable redirects to the same location (may be required by some servers)

.PARAMETER EnableCookies
Allow cookies to be stored and used

.PARAMETER CustomUserAgent
Custom fragment to append to "User-Agent" header in HTTP requests

.PARAMETER VersionPolicy
What type of artifacts does this repository store? Defaults to Release

.PARAMETER LayoutPolicy
Validate that all paths are maven artifact or metadata paths. Defaults to Strict.

.PARAMETER ContentDisposition
Add Content-Disposition header as 'Attachment' to disable some content from being inline in a browser. Defaults to Inline.

.PARAMETER Force
Don't prompt for confirmation before updating

.NOTES
This does not automatically migrate components from the previous settings.

.EXAMPLE
$ProxyParameters = @{
    Name = 'maven-central'
    ProxyRemoteUrl = 'https://repo1.maven.org/maven2/'
    CleanupPolicy = '90_Days'
    UseNegativeCache = $true
    VersionPolicy = 'Release'
    LayoutPolicy = 'Strict'
    ContentDisposition = 'Attachment'
}

Update-NexusMavenProxyRepository @ProxyParameters
# Updates the specified Maven proxy repository with the provided parameters
#>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/Update-NexusMavenProxyRepository/', DefaultParameterSetname = "Default", SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $ProxyRemoteUrl,

        [Parameter()]
        [int]
        $ContentMaxAgeMinutes,

        [Parameter()]
        [int]
        $MetadataMaxAgeMinutes,

        [Parameter()]
        [switch]
        $UseNegativeCache,

        [Parameter()]
        [int]
        $NegativeCacheTTLMinutes,

        [Parameter()]
        [string[]]
        $CleanupPolicy,

        [Parameter()]
        [string]
        $RoutingRule,

        [Parameter()]
        [switch]
        $Online,

        [Parameter()]
        [string]
        $BlobStoreName,

        [Parameter()]
        [Alias('StrictContentValidation')]
        [Switch]
        $UseStrictContentTypeValidation,

        [Parameter()]
        [switch]
        $UseNexusTrustStore,

        [Parameter(ParameterSetName = "Authentication")]
        [switch]
        $UseAuthentication,

        [Parameter(ParameterSetName = "Authentication", Mandatory)]
        [ValidateSet('Username', 'NTLM')]
        [string]
        $AuthenticationType,

        [Parameter(ParameterSetName = "Authentication", Mandatory)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(ParameterSetName = "Authentication")]
        [string]
        $HostnameFqdn,

        [Parameter(ParameterSetName = "Authentication")]
        [string]
        $DomainName,

        [Parameter()]
        [switch]
        $BlockOutboundConnections,

        [Parameter()]
        [switch]
        $EnableAutoBlocking,

        [Parameter()]
        [ValidateRange(0, 10)]
        [int]
        $ConnectionRetries,

        [Parameter()]
        [int]
        $ConnectionTimeoutSeconds,

        [Parameter()]
        [switch]
        $EnableCircularRedirects,

        [Parameter()]
        [switch]
        $EnableCookies,

        [Parameter()]
        [string]
        $CustomUserAgent,

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
        $ContentDisposition = 'Inline',

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
        $urislug = "/service/rest/v1/repositories/maven/proxy/$Name"

        $Body = Get-NexusRepositorySettings -Format maven2 -Name $Name -Type proxy -ErrorAction 'Stop' | Select-Object -Property * -ExcludeProperty format, type | Convert-ObjectToHashtable
        # Remove Authentication as password is never returned via API and always needs redefined if needing updated
        if (($Body.httpClient.authentication -ne $null) -and (-not($UseAuthentication))) {
            Write-Warning "Authentication is being removed from body as the API requires it to be defined in each update"
        }
        $Body.httpClient = $Body.httpClient | Convert-ObjectToHashtable 
        $Body.httpClient.Remove('Authentication')

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
            "UseStrictContentTypeValidation" {
                if ([bool]$Body.storage.strictContentTypeValidation -ne [bool]$UseStrictContentTypeValidation) {
                    [bool]$Body.storage.strictContentTypeValidation = [bool]$UseStrictContentTypeValidation
                    $Modified = $true
                }
            }
            "ProxyRemoteUrl" {
                if ($Body.proxy.remoteUrl -ne $ProxyRemoteUrl) {
                    $Body.proxy.remoteUrl = $ProxyRemoteUrl
                    $Modified = $true
                }
            }
            "ContentMaxAgeMinutes" {
                if ($Body.proxy.contentMaxAge -ne $ContentMaxAgeMinutes) {
                    $Body.proxy.contentMaxAge = $ContentMaxAgeMinutes
                    $Modified = $true
                }
            }
            "MetadataMaxAgeMinutes" {
                if ($Body.proxy.metadataMaxAge -ne $MetadataMaxAgeMinutes) {
                    $Body.proxy.metadataMaxAge = $MetadataMaxAgeMinutes
                    $Modified = $true
                }
            }
            "UseNegativeCache" {
                if ($Body.negativeCache.enabled -ne $UseNegativeCache.IsPresent) {
                    $Body.negativeCache.enabled = $UseNegativeCache.IsPresent
                    $Modified = $true
                }
            }
            "NegativeCacheTTLMinutes" {
                if ($Body.negativeCache.timeToLive -ne $NegativeCacheTTLMinutes) {
                    $Body.negativeCache.timeToLive = $NegativeCacheTTLMinutes
                    $Modified = $true
                }
            }
            "CleanupPolicy" {
                if ($CleanupPolicy) {
                    $Body.cleanup.policyNames = $CleanupPolicy
                    $Modified = $true
                }
            }
            "RoutingRule" {
                if ($Body.routingRule -ne $RoutingRule) {
                    $Body.routingRule = $RoutingRule
                    $Modified = $true
                }
            }
            "UseNexusTrustStore" {
                if ($Body.httpClient.connection.useTrustStore -ne $UseNexusTrustStore.IsPresent) {
                    $Body.httpClient.connection.useTrustStore = $UseNexusTrustStore.IsPresent
                    $Modified = $true
                }
            }
            "BlockOutboundConnections" {
                if ($Body.httpClient.blocked -ne $BlockOutboundConnections.IsPresent) {
                    $Body.httpClient.blocked = $BlockOutboundConnections.IsPresent
                    $Modified = $true
                }
            }
            "EnableAutoBlocking" {
                if ($Body.httpClient.autoBlock -ne $EnableAutoBlocking.IsPresent) {
                    $Body.httpClient.autoBlock = $EnableAutoBlocking.IsPresent
                    $Modified = $true
                }
            }
            "ConnectionRetries" {
                if ($Body.httpClient.connection.retries -ne $ConnectionRetries) {
                    $Body.httpClient.connection.retries = $ConnectionRetries
                    $Modified = $true
                }
            }
            "ConnectionTimeoutSeconds" {
                if ($Body.httpClient.connection.timeout -ne $ConnectionTimeoutSeconds) {
                    $Body.httpClient.connection.timeout = $ConnectionTimeoutSeconds
                    $Modified = $true
                }
            }
            "EnableCircularRedirects" {
                if ($Body.httpClient.connection.enableCircularRedirects -ne $EnableCircularRedirects.IsPresent) {
                    $Body.httpClient.connection.enableCircularRedirects = $EnableCircularRedirects.IsPresent
                    $Modified = $true
                }
            }
            "EnableCookies" {
                if ($Body.httpClient.connection.enableCookies -ne $EnableCookies.IsPresent) {
                    $Body.httpClient.connection.enableCookies = $EnableCookies.IsPresent
                    $Modified = $true
                }
            }
            "CustomUserAgent" {
                if ($Body.httpClient.connection.userAgentSuffix -ne $CustomUserAgent) {
                    $Body.httpClient.connection.userAgentSuffix = $CustomUserAgent
                    $Modified = $true
                }
            }
            "VersionPolicy" {
                if ($body.maven.versionPolicy -ne $VersionPolicy) {
                    $body.maven.versionPolicy = $VersionPolicy
                    $Modified = $true
                }
            }
            "LayoutPolicy" {
                if ($body.maven.layoutPolicy -ne $LayoutPolicy) {
                    $body.maven.layoutPolicy = $LayoutPolicy
                    $Modified = $true
                }
            }
            "ContentDisposition" {
                if ($body.maven.contentDisposition -ne $ContentDisposition) {
                    $body.maven.contentDisposition = $ContentDisposition
                    $Modified = $true
                }
            }
            "UseAuthentication" {
                switch ($AuthenticationType) {
                    'Username' {
                        $authentication = @{
                            type       = $AuthenticationType.ToLower()
                            username   = $Credential.UserName
                            password   = $Credential.GetNetworkCredential().Password
                            ntlmHost   = ''
                            ntlmDomain = ''
                        }
            
                        $body.httpClient.Add('authentication', $authentication)
                    }
    
                    'NTLM' {
                        if (-not $HostnameFqdn -and $DomainName) {
                            throw "Parameter HostnameFqdn and DomainName are required when using WindowsNTLM authentication"
                        }
                        else {
                            $authentication = @{
                                type       = $AuthenticationType
                                username   = $Credential.UserName
                                password   = $Credential.GetNetworkCredential().Password
                                ntlmHost   = $HostnameFqdn
                                ntlmDomain = $DomainName
                            }
                        }
           
                        $body.httpClient.Add('authentication', $authentication)
                    }
                }
                
            
                if ($Body.httpClient.authentication.type -ne $AuthenticationType) {
                    $Body.httpClient.authentication.type = $AuthenticationType
                    if ($AuthenticationType -eq 'Username') {
                        $Body.httpClient.authentication.username = $Credential.UserName
                        $Body.httpClient.authentication.Add('password', $Credential.GetNetworkCredential().Password)
                    }
                    elseif ($AuthenticationType -eq 'NTLM') {
                        $Body.httpClient.authentication.username = $Credential.UserName
                        $Body.httpClient.authentication.Add('password', $Credential.GetNetworkCredential().Password)
                        $Body.httpClient.authentication.ntlmHost = $HostnameFqdn
                        $Body.httpClient.authentication.ntlmDomain = $DomainName
                    }
                    $Modified = $true
                }
            }
        }

        if ($Modified) {
            if ($PSCmdlet.ShouldProcess($Name, "Update Maven Proxy Repository")) {
                Write-Verbose $($Body | ConvertTo-Json)
                Invoke-Nexus -UriSlug $urislug -Method Put -Body $Body
            }
        }
        else {
            Write-Verbose "No change to '$($Name)' was required."
        }
    }
}
