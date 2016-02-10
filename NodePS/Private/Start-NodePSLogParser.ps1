function Start-NodePSLogParser {

<#
    .SYNOPSIS

        Function to parse NodePSServer log files

    .EXAMPLE

        Start-NodePSLogParser -LogPath "C:\inetpub\logs\hourly.log"

#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (

    [Parameter(
        Mandatory = $true,
        HelpMessage = 'Log Path')]
    [string]$LogPath
)

	$File = $LogPath
	$Log = Get-Content $File | where {$_ -notLike "#[D,S-V]*" }
	$Columns = (($Log[0].TrimEnd()) -replace "#Fields: ", "" -replace "-","" -replace "\(","" -replace "\)","").Split(" ")
	$Count = $Columns.Length
	$Rows = $Log | where {$_ -notLike "#Fields"}
	$IISLog = New-Object System.Data.DataTable "IISLog"
	foreach ($Column in $Columns) {
		$NewColumn = New-Object System.Data.DataColumn $Column, ([string])
		$IISLog.Columns.Add($NewColumn)
	}
	foreach ($Row in $Rows) {
		$Row = $Row.Split(" ")
		$AddRow = $IISLog.newrow()
		for ($i=0;$i -lt $Count; $i++) {
			$ColumnName = $Columns[$i]
			$AddRow.$ColumnName = $Row[$i]
		}
		$IISLog.Rows.Add($AddRow)
	}
	$IISLog
}

