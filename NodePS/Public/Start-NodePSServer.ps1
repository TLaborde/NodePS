#Requires -RunAsAdministrator
function Start-NodePSServer {
<#
    .SYNOPSIS

        Powershell Web Server to serve HTML and Powershell web contents.

    .DESCRIPTION

        Listens a port to serve web content. Supports HTML and Powershell.

    .EXAMPLE

        Start-NodePSServer -IP 127.0.0.1 -Port 8080

    .EXAMPLE

        Start-NodePSServer -Hostname "NodePSserver.net" -Port 8080

    .EXAMPLE

        Start-NodePSServer -Hostname "NodePSserver.net" -Port 8080 -asJob

    .EXAMPLE

        Start-NodePSServer -Hostname "NodePSserver.net" -Port 8080 -SSL -SSLIP "127.0.0.1" -SSLPort 8443 -asJob

    .EXAMPLE

        Start-NodePSServer -Hostname "NodePSserver.net" -Port 8080 -Debug

    .EXAMPLE

        Start-NodePSServer -Hostname "NodePSserver.net,www.NodePSserver.net" -Port 8080

    .EXAMPLE

        Start-NodePSServer -Hostname "NodePSserver.net,www.NodePSserver.net" -Port 8080 -HomeDirectory "C:\inetpub\wwwroot"

    .EXAMPLE

        Start-NodePSServer -Hostname "NodePSserver.net,www.NodePSserver.net" -Port 8080 -HomeDirectory "C:\inetpub\wwwroot" -LogDirectory "C:\inetpub\wwwroot"

    .EXAMPLE

        Start-NodePSServer -Hostname "NodePSserver.net" -Port 8080 -CustomConfigDirectory "C:\inetpub\config"

#>

[CmdletBinding()]
param (

    # Hostname
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'IP Address or Hostname')]
    [Alias('IP')]
    [string]$Hostname = "localhost",

    # Port Number
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Port Number')]
    [int]$Port = 8080,

    # SSL IP Address
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SSL IP Address')]
    [string]$SSLIP = 127.0.0.1,

    # SSL Port Number
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SSL Port Number')]
    [int]$SSLPort = 8443,

    # SSL certificate Name
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SSL Friendly Name. Example: NodePSserver.net')]
    [string]$SSLName = "NodePSServer SSL Certificate",

    # Home Directory
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Home Directory. Example: C:\inetpub\wwwroot')]
    [string]$HomeDirectory = (Join-Path (Split-Path $PSScriptRoot) "Default\http"),

    # Log Directory
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Log Directory. Example: C:\inetpub\logs')]
    [string]$LogDirectory = (Join-Path (Split-Path $PSScriptRoot) "Default\logs"),

    # Custom Config Directory
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Custom Config Directory. Example: C:\inetpub\config')]
    [string]$CustomConfigDirectory = (Join-path (Split-Path $PSScriptRoot) "Default\Config"),

    # Custom Job Schedule
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Custom Job Schedule. Example: 1, 5, 10, 20, 30, 60')]
        [ValidateSet("1","5","10","20","30","60")]
    [string]$CustomJobSchedule = "5",

    # Background Job Credentials
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Run Background Job as a different User')]
    [System.Management.Automation.PSCredential]$JobCredentials,

    # Enable SSL
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Enable SSL')]
    [switch]$SSL,

    # Background Job
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Run As Background Job')]
    [switch]$asJob
)
    # Strict mode for clean code
    Set-StrictMode -Version latest

    $ServerConfig = Join-Path $CustomConfigDirectory "ServerConfig.ps1"
    $ThreadConfig  = Join-Path $CustomConfigDirectory "ThreadConfig.ps1"
    $CustomJob = Join-Path $CustomConfigDirectory "CustomJob.ps1"

    # Get NodePS Server Module Path
    $NodePSModulePath = Split-Path $PSScriptRoot

    # Break Script If Something's Wrong
    if (!(Test-IPSettings -Hostname $Hostname -SSLIP $SSLIP)) {
        return
    } else {
        if ($Hostname) {
            $Hostname = @($Hostname -split ",")
        }
        if ($SSLIP) {
            $SSLIP = @($SSLIP -split ",")
        }

    }

    # Enable Background Job
    if ($asJob) {
        if (!$JobCredentials) {
            Write-Warning "Please specify user credentials for NodePS Server background job."
            $JobCredentials = Get-Credential
            $JobPassword = $JobSecureCredentials.GetNetworkCredential().Password
        } 
        $JobUsername = $JobCredentials.UserName
        $JobPassword = $JobCredentials.GetNetworkCredential().Password

        $CheckTask = Get-ScheduledTask -TaskName "NodePSServer-$($Hostname[0])-$Port" -ErrorAction SilentlyContinue

        if ($CheckTask) {
            Write-Warning "This job already exists. You should run it from Scheduled Jobs."
            Write-Warning "Aborting..."
            return
        } else {
            try {
                # Prepare Job Information
                $taskName = "NodePSServer-$($Hostname[0])-$Port"
                $taskScriptBlock = "Import-Module $NodePSModulePath; "
                $taskScriptBlock += "$($MyInvocation.MyCommand) "

                foreach ($k in ($PSBoundParameters.keys.GetEnumerator() | Where-Object { $_ -notin @('asjob','jobcredentials') })) {
                    if ($PSBoundParameters[$k] -is [array]) {
                        $taskScriptBlock += "-$($k) @('$($PSBoundParameters[$k] -join "','")') "
                    } elseif($PSBoundParameters[$k] -is [switch] -and $PSBoundParameters[$k] -eq $true) {
                        $taskScriptBlock += "-$($k) "
                    } else {
                        $taskScriptBlock += "-$($k) $($PSBoundParameters[$k]) "
                    }
                }
                $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-noProfile -ExecutionPolicy Bypass -command `"&{$taskScriptBlock}`""
                $trigger = New-ScheduledTaskTrigger -AtStartup
                $settings = New-ScheduledTaskSettingsSet -Compatibility Win7 -Hidden -AllowStartIfOnBatteries
                $settings.ExecutionTimeLimit = "PT0S"

                Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -User $JobUsername -Password $JobPassword -Settings $settings -RunLevel Highest | Out-Null
                Start-ScheduledTask -TaskName $taskName | Out-Null

                # NodePS Server Welcome Banner

                Get-NodePSWelcomeBanner -Hostname $Hostname -Port $Port -SSL:$SSL -SSLIP $SSLIP -SSLPort $SSLPort
            } catch {
                Write-Debug "An error occured while trying to create the task."
                Write-Debug $_
            }
        }
    } else {

        # prepare a container with data shared across threads
        $SharedData = [hashtable]::Synchronized(@{})

        # Prepare a container with configuration value
        $NodePSConfig = @{}

        # NodePS Server Custom Config
        Write-Verbose "Reading server configuration file..."
        . $ServerConfig

        if ($PSBoundParameters['Debug']) {
            Write-Debug "Setting only 1 listening thread for debug."
            $NodePSConfig.Threads = 1
        }

        # Total processes is 2 * listening threads (to account for script threads) + 1 for the background thread
        try {
            $SessionState = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
            $MaxThread = 2 * $NodePSConfig.Threads + 1
            $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThread, $SessionState, $Host)
            $RunspacePool.Open()
            $SharedData.RunspacePool = $RunspacePool
        } catch {
            Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
            write-debug $_.Exception.tostring()
        }

        # If cached mode is active, we prepare the caching hashtable
        if ($NodePSConfig.CachedMode) {
            Write-Verbose "Cache Mode On, preparing the cache..."
            $SharedData.CachedPages = @{}
            $param ="Param(`$NodePSUserName, `$NodePSUserPassword, `$NodePSQuery, `$NodePSPost, `$SharedData)`n"

            foreach ($p in (Get-ChildItem $HomeDirectory -Filter "*ps1").fullname) {
                Write-Verbose "Caching $p"
                $SharedData.CachedPages[$p] = [scriptblock]::Create($param + [io.file]::ReadAllText($p))
            }
        }

        Write-Verbose "Starting background jobs..."
        # NodePS Server Scheduled Background Jobs
        $NodePSJobArgs = @($NodePSModulePath,$LogDirectory)
        $NodePSJob = Start-Job -scriptblock {
        param ($NodePSModulePath,$LogDirectory)
            Get-ChildItem $NodePSModulePath\Private\*.ps1 -Recurse | ForEach-Object {. $_.FullName }

            while ($true) {
                Start-Sleep -Seconds 3600
                New-NodePSLogHash -LogSchedule "Hourly" -LogDirectory $LogDirectory
            }
        } -ArgumentList $NodePSJobArgs

        # NodePS Server Custom Background Jobs
        $NodePSCustomJobScriptBlock = {
            param ($Hostname, $Port, $HomeDirectory, $LogDirectory, $CustomJob, $CustomJobSchedule, $SharedData)
            while ($true) {
                Start-Sleep -Seconds 60

                # Get Job Time
                [int]$JobTime = Get-Date -format mm
                if ($CustomJob) {
                    if ($CustomJobSchedule -eq "1") {
                        # NodePS Server Custom Jobs (at every 1 minute)
                        . $CustomJob
                    } elseif ($CustomJobSchedule -in @("5","10","20","30") -and !($JobTime % $CustomJobSchedule) ) {
                        # NodePS Server Custom Jobs (at every 5 minutes)
                        . $CustomJob
                    } elseif ($CustomJobSchedule -eq "60" -and $JobTime -eq 0) {
                        # NodePS Server Custom Jobs (at every hour)
                        . $CustomJob
                    }
                }
            }
        }
        $NodePSCustomJobParams = @{
            ScriptBlock = $NodePSCustomJobScriptBlock
            Hostname = $Hostname
            Port = $Port
            HomeDirectory = $HomeDirectory
            LogDirectory = $LogDirectory
            CustomJob = $CustomJob
            CustomJobSchedule = $CustomJobSchedule
            SharedData = $SharedData
            RunspacePool = $RunspacePool
        }

        $NodePSCustomJob = Invoke-BackgroundJob @NodePSCustomJobParams

        Write-Verbose "Create the HTTPListener..."
        try {
            $Listener = New-Object Net.HttpListener
        } catch {
            Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
            write-debug $_.Exception.tostring()
        }

        Write-Verbose "Add Prefix Urls..."
        try {
            foreach ($Host in $Hostname) {
                $Host = $Host -replace "^localhost$","+"
                $Prefix = "http://" + $Host + ":" + $Port + "/"
                $Listener.Prefixes.Add($Prefix)
            }

            if ($SSL) {
                foreach ($SSLIPAddress in $SSLIP) {
                    $SSLIPAddress = $SSLIPAddress -replace "^localhost$","+"
                    $Prefix = "https://" + $SSLIPAddress + ":" + $SSLPort + "/"
                    $Listener.Prefixes.Add($Prefix)
                }
            }
        } catch {
            Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
            Write-Debug $_.Exception.tostring()
        }

        Write-Verbose "Start Listener..."
        try {
            $Listener.Start()
        } catch {
            Write-Error "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
            write-Error $_.Exception.tostring()
            return
        }
        
        try {
            if ($SSL) {
                Write-Verbose "Configure SSL..."
                $NodePSCert = Get-ChildItem -Recurse Cert: | Where-Object { $_.FriendlyName -eq $SSLName }

                if (!$NodePSCert) {
                    Write-Warning "Couldn't find your SSL certificate."
                    write-Warning "Creating Self-Signed SSL certificate.."

                    Request-NodePSCertificate
                    $NodePSCert = Get-ChildItem -Recurse Cert: | Where-Object { $_.FriendlyName -eq "NodePSServer SSL Certificate" }
                }

                # Register SSL Certificate
                $CertThumbprint = $NodePSCert[0].Thumbprint
                Register-NodePSCertificate -SSLIP $SSLIP -SSLPort $SSLPort -Thumbprint $CertThumbprint
            }
        } catch {
            Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
            Write-Debug $_.Exception.tostring()
        }
        # NodePS Server Welcome Banner
        try {
            Get-NodePSWelcomeBanner -Hostname $Hostname -Port $Port -SSL:$SSL -SSLIP $SSLIP -SSLPort $SSLPort
        } Catch {
            Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
            Write-Debug $_.Exception.tostring()
        }

        $NodePSAsyncHTTPRequestParams = @{
            ScriptBlock = Get-NodePSThreadScriptBlock
            Listener = $Listener
            Hostname = $Hostname
            HomeDirectory = $HomeDirectory
            LogDirectory = $LogDirectory
            NodePSModulePath = $NodePSModulePath
            ThreadConfig = $ThreadConfig
            SharedData = $SharedData
            RunspacePool = $RunspacePool
        }
      
        # Let's finally start the listening thread(s)
        $Threads = 1..$NodePSConfig.Threads | ForEach-Object { Invoke-AsyncHTTPRequest @NodePSAsyncHTTPRequestParams }

        try {
            [System.Console]::TreatControlCAsInput = $true
            while ($true) {                                                                                                                   
                if ([System.Console]::KeyAvailable) {
                    $key = [System.Console]::ReadKey($true)
                    if (($key.modifiers -band [System.ConsoleModifiers]"control") -and ($key.key -eq "C")) {
                        Write-Verbose "Terminating..."
                        break
                    }
                    Start-Sleep -Seconds 1
                }
            }
        } finally {
            [console]::TreatControlCAsInput = $false
            try {
                $Listener.Stop()
                $Listener.Close()
            } Catch {
                Write-Warning $_.Exception.ToString()
            }

            while ([bool]($Threads | Where-Object {[bool]$_.Handle})) {
                ForEach ($thread in ($Threads | Where-Object {$_.Handle.IsCompleted -eq $True})) {
                    $Thread.Instance.EndInvoke($Thread.Handle)
                    $Thread.Instance.Dispose()
                    $Thread.Instance = $Null
                    $Thread.Handle = $Null
                }
                if ($Threads | Where-Object {[bool]$_.Handle}) {
                    Write-verbose ("Waiting for {0} threads to finish..." -f ($Threads | Where-Object {[bool]$_.Handle}).count)
                }
                Start-Sleep -Seconds 1
            }
            $RunspacePool.Close() | Out-Null
            $RunspacePool.Dispose() | Out-Null

            foreach ($session in Get-PSSession) {
                Write-Verbose ("Closing session {0}" -f $session.Name)
            }

            # We stop and close the internal job
            $NodePSJob | Stop-Job -PassThru | Remove-Job |Out-Null
        }
    }
}


