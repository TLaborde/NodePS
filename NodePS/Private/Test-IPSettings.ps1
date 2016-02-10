# NodePS Server IP Address Verification
function Test-IPSettings {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false)]
        $Hostname,

        [Parameter(
            Mandatory = $false)]
        $SSLIP
    )
    if ($Hostname -or $SSLIP) {
	    $IPAddresses = @($Hostname -split "," ; $SSLIP -split "," )
	    foreach ($IPAddress in $IPAddresses) {
		    if ($IPAddress -ne "127.0.0.1" -and $IPAddress -ne "::1") {
			    if ($IPAddress -as [ipaddress]) {
				    if ($IPAddress -notin (Get-WmiObject Win32_NetworkAdapterConfiguration).IPaddress) {
					    Write-Warning "$IPAddress does not exist on your current network configuration."
					    Write-Warning "Aborting.."
					    return $false
				    }
			    }
		    }
	    }
    }

    return $true
}

