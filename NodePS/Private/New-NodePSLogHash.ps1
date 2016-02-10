function New-NodePSLogHash {

<#
    .SYNOPSIS

        Function to hash NodePSServer log file

    .EXAMPLE

        New-NodePSLogHash -LogSchedule "Hourly" -LogDirectory "C:\inetpub\logs"

#>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Log Schedule')]
        [string]$LogSchedule,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Log Directory Path')]
        [string]$LogDirectory
    )

	if ($LogSchedule -eq "Hourly") {
		$LogNameFormatLastRound = (Get-Date).AddHours(-1).ToString("yyMMddHH")
	} else {
		$LogNameFormatLastRound = (Get-Date).AddDays(-1).ToString("yyMMdd")
	}

	$LogFileNameLastRound = "u_ex" + $LogNameFormatLastRound + ".log"
	$LogFilePathLastRound = $LogDirectory + "\" + $LogFileNamLastRound
	$LastLogFilePath = $LogFilePathLastRound

	$SigFileName = "u_ex" + $LogNameFormatLastRound + ".sign"
	$SigFilePath = $LogDirectory + "\" + $SigFileName
	$DateFileName = "u_ex" + $LogNameFormatLastRound + ".date"
	$DateFilePath = $LogDirectory + "\" + $DateFileName

	if ([System.IO.File]::Exists($LastLogFilePath)) {
		if (![System.IO.File]::Exists($SigFilePath)) {
			$LogHashJobArgs = @($LastLogFilePath,$SigFilePath,$DateFilePath)

			try {
				$LogHashJob = Start-Job -ScriptBlock {
					param ($LastLogFilePath, $SigFilePath, $DateFilePath)
					if (![System.IO.File]::Exists($DateFilePath)) {
						$HashAlgorithm = "MD5"
						$HashType = [Type] "System.Security.Cryptography.$HashAlgorithm"
						$Hasher = $HashType::Create()
						$DateString = Get-Date -uformat "%d.%m.%Y"
						$TimeString = (w32tm /stripchart /computer:time.ume.tubitak.gov.tr /samples:1)[-1].split("")[0]
						$DateString = $DateString + " " + $TimeString
						$InputStream = New-Object IO.StreamReader $LastLogFilePath
						$HashBytes = $Hasher.ComputeHash($InputStream.BaseStream)
						$InputStream.Close()
						$Builder = New-Object System.Text.StringBuilder
						$HashBytes | Foreach-Object { [void] $Builder.Append($_.ToString("X2")) }
						$HashString = $Builder.ToString()
						$HashString = $HashString + " " + $DateString
						$Stream = [System.IO.StreamWriter]$SigFilePath
						$Stream.Write($HashString)
						$Stream.Close()
						$Stream = [System.IO.StreamWriter]$DateFilePath
						$Stream.Write($DateString)
						$Stream.Close()
						$InputStream = New-Object IO.StreamReader $SigFilePath
						$HashBytes = $Hasher.ComputeHash($InputStream.BaseStream)
						$InputStream.Close()
						$Builder = New-Object System.Text.StringBuilder
						$HashBytes | Foreach-Object { [void] $Builder.Append($_.ToString("X2")) }
						$HashString = $Builder.ToString()
						$Stream = [System.IO.StreamWriter]$SigFilePath
						$Stream.Write($HashString)
						$Stream.Close()
					}
				} -ArgumentList $LogHashJobArgs
			} Catch {
				Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
                write-debug $_.Exception.tostring()
			}
		}
	}
	else {
		Write-Debug "Could not find log file. $LogDirectory\debug.txt"
	}
}


