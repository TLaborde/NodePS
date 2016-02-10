function Invoke-BackgroundJob {

<#
    .SYNOPSIS

        Function to invoke async HTTP request

    .EXAMPLE

        Invoke-AsyncHTTPRequest

#>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Script Block')]
        $ScriptBlock,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Hostname')]
        $Hostname,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Port')]
        $Port,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Home Directory. Example: C:\inetpub\wwwroot')]
        [string]$HomeDirectory,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Log Directory. Example: C:\inetpub\wwwroot')]
        [string]$LogDirectory,

	    [Parameter(
            Mandatory = $false,
            HelpMessage = 'Custom Job file Path')]
        [string]$CustomJob,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Custom Job Schedule')]
        [int]$CustomJobSchedule,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Shared data container')]
        [object]$SharedData,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Runspace Pool')]
        $RunspacePool
    )

	$Pipeline = [System.Management.Automation.PowerShell]::Create()
	$null = $Pipeline.AddScript($ScriptBlock)
	$null = $Pipeline.AddArgument($Hostname)
	$null = $Pipeline.AddArgument($Port)
	$null = $Pipeline.AddArgument($HomeDirectory)
	$null = $Pipeline.AddArgument($LogDirectory)
	$null = $Pipeline.AddArgument($CustomJob)
	$null = $Pipeline.AddArgument($CustomJobSchedule)
    $null = $Pipeline.AddArgument($SharedData)
    $Pipeline.RunspacePool = $RunspacePool
    [psobject]@{
        "Handle" = $Pipeline.BeginInvoke()
        "Instance" = $Pipeline
    }
}
