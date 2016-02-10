function Get-DirectoryContent {

<#
    .SYNOPSIS

        Function to get directory content

    .EXAMPLE

        Get-DirectoryContent -Path "C:\" -HeaderName "NodePSserver.net" -RequestURL "http://NodePSserver.net" -SubfolderName "/"

#>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Directory Path')]
        [string]$Path,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Header Name')]
        [string]$HeaderName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Request URL')]
        [string]$RequestURL,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Subfolder Name')]
        [string]$SubfolderName
    )

@"
<html>
<head>
<title>$($HeaderName)</title>
</head>
<body>
<h1>$($HeaderName) - $($SubfolderName)</h1>
<hr>
"@

$ParentDirectory = $RequestURL + $Subfoldername + "../"

@"
<a href="$($ParentDirectory)">[To Parent Directory]</a><br><br>
<table cellpadding="5">
"@

    $Files = (Get-ChildItem "$Path")
    foreach ($File in $Files) {
        $FileURL = $RequestURL + $Subfoldername + $File.Name
        if (!$File.Length) { 
            $FileLength = "[dir]" 
        } else { 
            $FileLength = $File.Length 
        }
@"
<tr>
<td align="right">$($File.LastWriteTime)</td>
<td align="right">$($FileLength)</td>
<td align="left"><a href="$($FileURL)">$($File.Name)</a></td>
</tr>
"@
    }
@"
</table>
<hr>
</body>
</html>
"@
}

