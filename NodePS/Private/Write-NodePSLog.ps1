# NodePS Server Logging Module
# Fields: date time s-sitename s-computername s-ip cs-method cs-uri-stem s-port c-ip cs-version cs(User-Agent) cs(Cookie) cs(Referer) cs-host sc-status
function Write-NodePSLog {
    [CmdletBinding()]param()
    $LogDate = Get-Date -format yyyy-MM-dd
    $LogTime = Get-Date -format HH:mm:ss
    $LogSiteName = $Hostname
    if ($LogSiteName -eq "+") { $LogSiteName = "localhost" }
    $LogComputerName = Get-Content env:computername
    $LogServerIP = $Request.LocalEndPoint.Address
    $LogMethod = $Request.HttpMethod
    $LogUrlStem = $Request.RawUrl
    $LogServerPort = $Request.LocalEndPoint.Port
    $LogClientIP = $Request.RemoteEndPoint.Address
    $LogClientVersion = $Request.ProtocolVersion
    if (!$LogClientVersion) { $LogClientVersion = "-" } else { $LogClientVersion = "HTTP/" + $LogClientVersion }
    $LogClientAgent = [string]$Request.UserAgent
    if (!$LogClientAgent) { $LogClientAgent = "-" } else { $LogClientAgent = $LogClientAgent.Replace(" ","+") }
    $LogClientCookie = [string]$Response.Cookies.Value
    if (!$LogClientCookie) { $LogClientCookie = "-" } else { $LogClientCookie = $LogClientCookie.Replace(" ","+") }
    $LogClientReferrer = [string]$Request.UrlReferrer
    if (!$LogClientReferrer) { $LogClientReferrer = "-" } else { $LogClientReferrer = $LogClientReferrer.Replace(" ","+") }
    $LogHostInfo = [string]$LogServerIP + ":" + [string]$LogServerPort

    # Log Output
    $LogOutput = "$LogDate $LogTime $LogSiteName $LogComputerName $LogServerIP $LogMethod $LogUrlStem $LogServerPort $LogClientIP $LogClientVersion $LogClientAgent $LogClientCookie $LogClientReferrer $LogHostInfo $LogResponseStatus"

    # Logging to Log File
    $LogNameFormat = if ($LogSchedule -eq "Hourly") {
	    Get-Date -format yyMMddHH
    } else {
	    Get-Date -format yyMMdd
    }
	$LogFileName = "u_ex" + $LogNameFormat + ".log"
	$LogFilePath = $LogDirectory + "\" + $LogFileName

    if ($LastCheckDate -ne $LogNameFormat) {
	    if (![System.IO.File]::Exists($LogFilePath)) {
		    $LogHeader = "#Fields: date time s-sitename s-computername s-ip cs-method cs-uri-stem s-port c-ip cs-version cs(User-Agent) cs(Cookie) cs(Referer) cs-host sc-status"
		    Add-Content -Path $LogFilePath -Value $LogHeader -EA SilentlyContinue
	    }

	    # Set Last Check Date
	    $LastCheckDate = $LogNameFormat
    }

    try {
	    Add-Content -Path $LogFilePath -Value $LogOutput -EA SilentlyContinue
    } Catch {
        Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
        write-debug $_.Exception.tostring()
    }
}


