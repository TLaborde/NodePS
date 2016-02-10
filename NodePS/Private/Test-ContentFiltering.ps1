# NodePS Server Content Filtering Module
function Test-ContentFiltering {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true)]
        $ContentFiltering,

        [Parameter(
            Mandatory = $true)]
        $ContentFilterBlackList,

        [Parameter(
            Mandatory = $true)]
        $MimeType
    )
    if ($ContentFiltering -eq "On") {
	    if ($ContentFilterBlackList -match $MimeType) {
		    Write-Debug "$MimeType is not allowed, dropping.."
		    $true
	    }
	    else {
		    $false
	    }
    }
    else {
	    $false
    }
}

