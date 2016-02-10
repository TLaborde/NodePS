function Register-NodePSCertificate {

<#
    .SYNOPSIS

        Function to register NodePS Certificate

    .EXAMPLE

        Register-NodePSCertificate -SSLIP "10.10.10.2" -SSLPort "8443" -Thumbprint "45F53D35AB630198F19A27931283"

#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SSL IP Address')]
    [string]$SSLIP,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SSL Port Number')]
    [string]$SSLPort,

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SSL Thumbprint')]
    $Thumbprint,

	[Parameter(
        Mandatory = $false,
        HelpMessage = 'Debug Mode')]
    $DebugMode = $false
)

	$SSLIPAddresses = @($SSLIP.Split(","))

	foreach ($SSLIPAddress in $SSLIPAddresses) {
		$IPPort = $SSLIPAddress + ":" + $SSLPort

		if ($DebugMode) {
			# Remove Previous SSL Bindings
			netsh http delete sslcert ipport="$IPPort"

			# Add SSL Certificate
			netsh http add sslcert ipport="$IPPort" certhash="$Thumbprint" appid="{00112233-4455-6677-8899-AABBCCDDEEFF}"
		}
		else {
			# Remove Previous SSL Bindings
			netsh http delete sslcert ipport="$IPPort" | Out-Null

			# Add SSL Certificate
			netsh http add sslcert ipport="$IPPort" certhash="$Thumbprint" appid="{00112233-4455-6677-8899-AABBCCDDEEFF}" | Out-Null
		}
	}
}

