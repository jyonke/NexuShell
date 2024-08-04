function Update-NexusGoGroupRepository {
    <#
    .SYNOPSIS
    Updates properties of a given Go group repository

    .PARAMETER Name
    The name of the Go group repository to update

    .PARAMETER GroupMembers
    The Go Repositories to add as group members

    .PARAMETER Online
    Indicates if the repository should be online

    .PARAMETER BlobStoreName
    The name of the blob store to use

    .PARAMETER UseStrictContentValidation
    Indicates if strict content type validation should be enforced

    .PARAMETER Force
    Don't prompt for confirmation before updating

    .NOTES
    This does not automatically migrate components from the previous settings.

    .EXAMPLE
    Update-NexusGoGroupRepository -Name GoGroup -GroupMembers GoHostedLinux,GoProxy

    # Updates the specified Go group repository with the provided parameters
    #>
    [CmdletBinding(HelpUri = 'https://nexushell.dev/Update-NexusGoGroupRepository/', SupportsShouldProcess, ConfirmImpact = 'High')]
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
        $urislug = "/service/rest/v1/repositories/go/group/$Name"

        $Body = Get-NexusRepositorySettings -Format go -Name $Name -Type group -ErrorAction 'Stop' | Select-Object -Property * -ExcludeProperty format, type | Convert-ObjectToHashtable

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
        }

        if ($Modified) {
            if ($PSCmdlet.ShouldProcess($Name, "Update Go Group Repository")) {
                Write-Verbose $($Body | ConvertTo-Json)
                Invoke-Nexus -UriSlug $urislug -Method Put -Body $Body
            }
        }
        else {
            Write-Verbose "No change to '$($Name)' was required."
        }
    }
}
