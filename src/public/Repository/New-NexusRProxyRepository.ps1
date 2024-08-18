function New-NexusRProxyRepository {
    <#
.SYNOPSIS
Creates a new R Proxy Repository

.DESCRIPTION
Creates a new R Proxy Repository

.PARAMETER Name
The name to give the repository

.PARAMETER ProxyRemoteUrl
Location of the remote repository being proxied, e.g. https://api.R.org/v3/index.json

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

.EXAMPLE

$ProxyParameters = @{
    Name = 'RProxy'
    ProxyRemoteUrl = 'https://remote.repository.com'
}

New-NexusRProxyRepository @ProxyParameters

.EXAMPLE

$ProxyParameters = @{
    Name = 'RProxy'
    ProxyRemoteUrl = 'https://remote.repository.com'
    UseAuthentication = $true
    AuthenticationType = 'Username'
    Credential = (Get-Credential)

}

New-NexusRProxyRepository @ProxyParameters
#>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/New-NexusRProxyRepository/', DefaultParameterSetname = "Default")]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter(Mandatory)]
        [String]
        $ProxyRemoteUrl,

        [Parameter()]
        [String]
        $ContentMaxAgeMinutes = '1440',

        [Parameter()]
        [String]
        $MetadataMaxAgeMinutes = '1440',

        [Parameter()]
        [Switch]
        $UseNegativeCache,

        [Parameter()]
        [String]
        $NegativeCacheTTLMinutes = '1440',

        [Parameter()]
        [String]
        $CleanupPolicy,

        [Parameter()]
        [String]
        $RoutingRule,

        [Parameter()]
        [Switch]
        $Online = $true,

        [Parameter()]
        [String]
        $BlobStoreName = 'default',

        [Parameter()]
        [Alias('StrictContentValidation')]
        [Switch]
        $UseStrictContentTypeValidation = $true,

[Parameter()]
        [Switch]
        $UseNexusTrustStore = $false,

        [Parameter(ParameterSetName = "Authentication")]
        [Switch]
        $UseAuthentication,

        [Parameter(ParameterSetName = "Authentication", Mandatory)]
        [ValidateSet('Username', 'NTLM')]
        [String]
        $AuthenticationType,

        [Parameter(ParameterSetName = "Authentication", Mandatory)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(ParameterSetName = "Authentication")]
        [String]
        $HostnameFqdn,

        [Parameter(ParameterSetName = "Authentication")]
        [String]
        $DomainName,

        [Parameter()]
        [Switch]
        $BlockOutboundConnections = $false,

        [Parameter()]
        [Switch]
        $EnableAutoBlocking = $false,

        [Parameter()]
        [ValidateRange(0, 10)]
        [String]
        $ConnectionRetries,

        [Parameter()]
        [String]
        $ConnectionTimeoutSeconds,

        [Parameter()]
        [Switch]
        $EnableCircularRedirects = $false,

        [Parameter()]
        [Switch]
        $EnableCookies = $false,

        [Parameter()]
        [String]
        $CustomUserAgent
    )
    begin {

        if (-not $header) {
            throw "Not connected to Nexus server! Run Connect-NexusServer first."
        }

        $urislug = "/service/rest/v1/repositories/r/proxy"

    }
    process {

        $body = @{
            name          = $Name
            online        = [bool]$Online
            storage       = @{
                blobStoreName               = $BlobStoreName
                strictContentTypeValidation = [bool]$UseStrictContentTypeValidation
            }
            cleanup       = @{
                policyNames = @($CleanupPolicy)
            }
            proxy         = @{
                remoteUrl      = $ProxyRemoteUrl
                contentMaxAge  = $ContentMaxAgeMinutes
                metadataMaxAge = $MetadataMaxAgeMinutes
            }
            negativeCache = @{
                enabled    = [bool]$UseNegativeCache
                timeToLive = $NegativeCacheTTLMinutes
            }
            routingRule   = $RoutingRule
            httpClient    = @{
                blocked    = [bool]$BlockOutboundConnections
                autoBlock  = [bool]$EnableAutoBlocking
                connection = @{
                    retries                 = $ConnectionRetries
                    userAgentSuffix         = $CustomUserAgent
                    timeout                 = $ConnectionTimeoutSeconds
                    enableCircularRedirects = [bool]$EnableCircularRedirects
                    enableCookies           = [bool]$EnableCookies
                    useTrustStore           = [bool]$UseNexusTrustStore
                }
            }

        }

        if ($UseAuthentication) {
        
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
        
        }

        Write-Verbose $($Body | ConvertTo-Json)
        Invoke-Nexus -UriSlug $urislug -Body $Body -Method POST

    }

}