function Get-NodePSThreadScriptBlock {

    return {
        Param($Listener, $Hostname, $HomeDirectory, $LogDirectory, $NodePSModulePath, $ThreadConfig, $SharedData)
        # we need to load the private function manually...
        Get-ChildItem $NodePSModulePath\Private\*.ps1 -Recurse | ForEach-Object {. $_.FullName }

        . $ThreadConfig

        # Set Home Directory
        [IO.Directory]::SetCurrentDirectory("$HomeDirectory")

        # Get Server Requests
        while ($Listener.IsListening) {
            # Set Default Authentication
            $Listener.AuthenticationSchemes = "Anonymous";

            # Set Authentication
            if ($BasicAuthentication -eq "On") { $Listener.AuthenticationSchemes = "Basic"; }
            if ($NTLMAuthentication -eq "On") { $Listener.AuthenticationSchemes = "NTLM"; }
            if ($WindowsAuthentication -eq "On") { $Listener.AuthenticationSchemes = "IntegratedWindowsAuthentication"; }

            # Open Connection
            $Context = $Listener.GetContext()

            # Authentication Module
            $Identity, $NodePSUserName, $NodePSUserPassword = Get-Authentication -Context $Context -BasicAuthentication $BasicAuthentication -WindowsAuthentication $WindowsAuthentication

            $File = $Context.Request.Url.LocalPath
            $Response = $Context.Response
            $Response.Headers.Add("Accept-Encoding","gzip");
            $Response.Headers.Add("Server","NodePS Server");
            $Response.Headers.Add("X-Powered-By","Microsoft PowerShell");
            $Response.Headers.Add("Access-Control-Allow-Origin","*");

            # Set Request Parameters
            $Request = $Context.Request
            $InputStream = $Request.InputStream
            $ContentEncoding = $Request.ContentEncoding
            $ContentType = $Request.ContentType

            # IP Restriction Module
            $IPSessionDrop = Test-IPRestriction -Request $Request -IPRestriction $IPRestriction -IPWhiteList $IPWhiteList

            # Get Query String
            $NodePSQuery = Get-NodePSQueryString -Request $Request

            # Get Post Stream
            $NodePSPost = Get-NodePSPostStream -InputStream $InputStream -ContentEncoding $ContentEncoding  -ContentType $ContentType

            # Get Default Document
            if ($File -notlike "*.*" -and $File -like "*/") {
                $FolderPath = [System.IO.Directory]::GetCurrentDirectory() + $File
                $RequstURL = [string]$Request.Url
                $SubfolderName = $File
                $File = $File + $DefaultDocument
            }
            elseif ($File -notlike "*.*" -and $File -notlike "*/") {
                $FolderPath = [System.IO.Directory]::GetCurrentDirectory() + $File + "/"
                $RequstURL = [string]$Request.Url + "/"
                $SubfolderName = $File + "/"
                $File = $File + "/" + $DefaultDocument
            }
            else {
                $FolderPath = $Null;
            }

            $File = [System.IO.Directory]::GetCurrentDirectory() + $File
            $MimeType = Get-MimeType -Extension ((Get-ChildItem $File -EA SilentlyContinue).Extension)

            # NodePS API Support
            if ($File -like "*.psxml") {
                $File = $File.Replace(".psxml",".ps1")
            } elseif ($File -like "*.psjson") {
                $File = $File.Replace(".psjson",".ps1")
            } 
            # We do this replace to match the files in the cache if needed
            $File = $File -replace "/","\"

            # Content Filtering Module
            $ContentSessionDrop = Test-ContentFiltering -ContentFiltering $ContentFiltering -ContentFilterBlackList $ContentFilterBlackList -MimeType $MimeType

            # Check if the file exists in cache or on disk
            if ($NodePSConfig.CachedMode) {
                $fileExist = $SharedData.CachedPages.ContainsKey($file) -or ($file -notmatch ".*\.ps1$" -and [System.IO.File]::Exists($File))
            } else {
                $fileExist = [System.IO.File]::Exists($File)
            }

            # Stream Content
            if ((-not $ContentSessionDrop) -and (-not $IPSessionDrop) -and $fileExist) {
                if ($MimeType -in @("text/ps1","text/psxml","text/psjson")) {
                    try {
                        $Response.ContentType = Switch ($MimeType) {
                            "text/ps1" { "text/html" }
                            "text/psxml" { "text/xml" }
                            "text/psjson" { "application/json" }
                        }
                        $Response.StatusCode = [System.Net.HttpStatusCode]::OK
                        $LogResponseStatus = $Response.StatusCode
                        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
                        $Response = New-Object IO.StreamWriter($Response.OutputStream,$Utf8NoBomEncoding)
                        if ($NodePSConfig.CachedMode) {
                            $ScriptBlock = $SharedData.CachedPages[$file]
                        } else {
                            $param ="Param(`$NodePSUserName, `$NodePSUserPassword, `$NodePSQuery, `$NodePSPost, `$SharedData, `$Identity)`n"
                            $ScriptBlock = [scriptblock]::Create($param + ([System.IO.File]::ReadAllText($file)))
                        }
                        $ResponseThread = [powershell]::Create()
                        $null = $ResponseThread.AddScript($ScriptBlock)
                        $null = $ResponseThread.AddArgument($NodePSUserName)
                        $null = $ResponseThread.AddArgument($NodePSUserPassword)
                        $null = $ResponseThread.AddArgument($NodePSQuery)
                        $null = $ResponseThread.AddArgument($NodePSPost)
                        $null = $ResponseThread.AddArgument($SharedData)
                        $null = $ResponseThread.AddArgument($Identity)
                        $ResponseThread.RunspacePool = $SharedData.RunspacePool
                        $ResponseHandle = $ResponseThread.BeginInvoke()
                        Do {
                            Start-Sleep -Milliseconds 50
                        }
                        While ($ResponseHandle.IsCompleted -contains $false)
                        $ResponseData = $ResponseThread.EndInvoke($ResponseHandle)
                        $ResponseThread.Dispose()
                        foreach ($o in $ResponseData) {
                            $Response.WriteLine($o)
                        }
                    } Catch {
                        Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
                        write-debug $_.Exception.tostring()
                    }
                } else { #for all other files, read static content
                    try {
                        $Response.ContentType = "$MimeType"
                        $FileContent = [System.IO.File]::ReadAllBytes($File)
                        $Response.ContentLength64 = $FileContent.Length
                        $Response.StatusCode = [System.Net.HttpStatusCode]::OK
                        $LogResponseStatus = $Response.StatusCode
                        $Response.OutputStream.Write($FileContent, 0, $FileContent.Length)
                    } Catch {
                        Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
                        write-debug $_.Exception.tostring()
                    }
                }
            } else { #requesting a folder, not a file
                # Content Filtering and IP Restriction Control
                if ((-not $ContentSessionDrop) -and (-not $IPSessionDrop) -and $FolderPath) {
                    $TestFolderPath = Test-Path -Path $FolderPath
                } else {
                    $TestFolderPath = $false
                }

                if ($DirectoryBrowsing -and $TestFolderPath) {
                    try {
                        $Response.ContentType = "text/html"
                        $Response.StatusCode = [System.Net.HttpStatusCode]::OK
                        $LogResponseStatus = $Response.StatusCode
                        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
                        $Response = New-Object IO.StreamWriter($Response.OutputStream,$Utf8NoBomEncoding)
                        if ($Hostname -eq "+") { $HeaderName = "localhost" } else { $HeaderName = $Hostname[0] }
                        $DirectoryContent = (Get-DirectoryContent -Path "$FolderPath" -HeaderName $HeaderName -RequestURL $RequestURL -SubfolderName $SubfolderName)
                        $Response.WriteLine("$DirectoryContent")
                    } Catch {
                        Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
                        write-debug $_.Exception.tostring()
                    }
                } else { #folder requested, no folder browsing allowed or folder not exist, you get a 404 (maybe a 501 would be better?)
                    try {
                        $Response.ContentType = "text/html"
                        $Response.StatusCode = [System.Net.HttpStatusCode]::NotFound
                        $LogResponseStatus = $Response.StatusCode
                        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
                        $Response = New-Object IO.StreamWriter($Response.OutputStream,$Utf8NoBomEncoding)
                        $Response.WriteLine($(Get-404PageContent -Hostname $Hostname))
                    } Catch {
                        Write-Debug "Exception in $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.Line)"
                        write-debug $_.Exception.tostring()
                    }
                }
            }

            # Logging Module
            Write-NodePSLog

            # Close Connection
            try {
                $Response.Close()
            } Catch {
                $_.Exception.ToString()  | ForEach-Object { Add-Content -Value $_ -Path "$LogDirectory\debug.txt" }
                Add-Content -Value $_.InvocationInfo.ScriptLineNumber -Path "$LogDirectory\debug.txt"
            }
        }
    }
}