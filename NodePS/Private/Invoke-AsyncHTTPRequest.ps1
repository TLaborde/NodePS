function Invoke-AsyncHTTPRequest {

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
            HelpMessage = 'Listener')]
        $Listener,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Hostname')]
        $Hostname,

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
            HelpMessage = 'NodePSServer Module Path')]
        [string]$NodePSModulePath,

	    [Parameter(
            Mandatory = $false,
            HelpMessage = 'Thread Config Path')]
        [string]$ThreadConfig,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Shared data container')]
        [object]$SharedData,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Thread pool')]
        [object]$RunspacePool
    )

	$Pipeline = [System.Management.Automation.PowerShell]::Create()
	$null = $Pipeline.AddScript($ScriptBlock)
	$null = $Pipeline.AddArgument($Listener)
	$null = $Pipeline.AddArgument($Hostname)
	$null = $Pipeline.AddArgument($HomeDirectory)
	$null = $Pipeline.AddArgument($LogDirectory)
	$null = $Pipeline.AddArgument($NodePSModulePath)
	$null = $Pipeline.AddArgument($ThreadConfig)
    $null = $Pipeline.AddArgument($SharedData)
    $Pipeline.RunspacePool = $RunspacePool
    [psobject]@{
        "Handle" = $Pipeline.BeginInvoke()
        "Instance" = $Pipeline
    }
}
