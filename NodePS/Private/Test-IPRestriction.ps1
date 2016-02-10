# NodePS Server IP Restriction Module
function Test-IPRestriction {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true)]
        $Request,

        [Parameter(
            Mandatory = $true)]
        $IPRestriction,

        [Parameter(
            Mandatory = $true)]
        $IPWhiteList
    )
    $ClientIPAddr = $Request.RemoteEndPoint.Address

    if ($IPRestriction -eq "On" -and !($IPWhiteList -match $ClientIPAddr)) {
		Write-Warning "$ClientIPAddr has no permission, dropping.."
		return $true
	}
    return $false

}

