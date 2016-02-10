function Get-NodePSQueryString {

<#
    .SYNOPSIS

        Function to get query string

    .EXAMPLE

        Get-NodePSQueryString -Request $Request

#>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Request')]
        $Request
    )

	if ($Request) {
		$NodePSQueryString = $Request.RawUrl.Split("?")[1]
		$QueryStrings = $Request.QueryString

		$Properties = New-Object Psobject
		$Properties | Add-Member Noteproperty NodePSQueryString $NodePSQueryString
		foreach ($Query in $QueryStrings) {
			$QueryString = $Request.QueryString["$Query"]
			if ($QueryString -and $Query) {
				$Properties | Add-Member Noteproperty $Query $QueryString
			}
		}
		Write-Output $Properties
	}
}

