function Get-NodePSWelcomeBanner {

<#
    .SYNOPSIS

        Function to get welcome banner

    .EXAMPLE

        Get-NodePSWelcomeBanner -Hostname "localhost" -Port "8080" -SSL -SSLIP "10.10.10.2" -SSLPort "8443"

#>

    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'IP Address or Hostname')]
	    [Alias('IP')]
        [string[]]$Hostname,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Port Number')]
        [int]$Port,

	    [Parameter(
            Mandatory = $false,
            HelpMessage = 'Enable SSL')]
        [switch]$SSL,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'SSL IP Address')]
        [string[]]$SSLIP,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'SSL Port Number')]
        [int]$SSLPort
    )
	# Get Port
	if ($Port -ne 80) {
		[string]$Port = ":$Port"
	} else {
		$Port = $null
	}

	# Get SSL Port
	if ($SSLPort -ne "443") {
        [string]$SSLPort = ":$SSLPort"
    } else {
        [string]$SSLPort = $null
	}

	Write-Host " "
	Write-Host "  Welcome to NodePS Server"
	Write-Host " "
	Write-Host " "
	Write-Host "  You can start browsing your webpage from:"
    foreach ($h in $Hostname) {
        if ($h -eq "+") { $h = "localhost" }
	    Write-Host "  http://$h$Port"
    }

	if ($SSL) {
        foreach ($ip in $SSLIP) {
		    Write-Host "  https://$ip$SSLPort"
        }
	}

	Write-Host " "
	Write-Host " "
	Write-Host "  Thanks for using NodePS Server.."
	Write-Host " "
	Write-Host " "
	Write-Host " "
}
