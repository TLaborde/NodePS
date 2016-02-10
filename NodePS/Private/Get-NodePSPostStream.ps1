function Get-NodePSPostStream {

<#
    .SYNOPSIS

        Function to get php post stream

    .EXAMPLE

        Get-NodePSPostStream -InputStream $InputStream -ContentEncoding $ContentEncoding

#>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Input Stream')]
        $InputStream,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Content Encoding')]
        $ContentEncoding,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Content Type')]
        $ContentType
    )

	$NodePSPostStream = New-Object IO.StreamReader ($InputStream,$ContentEncoding)
	$NodePSPostStream = $NodePSPostStream.ReadToEnd()
	$NodePSPostStream = $NodePSPostStream.ToString()

	if ($NodePSPostStream) {
        $Properties = New-Object Psobject

        if ($ContentType -eq "application/json") {
            $Properties = $NodePSPostStream | ConvertFrom-Json
        } else {
            $NodePSCommand = $NodePSPostStream -Split "&"
            foreach ($Post in $NodePSCommand) {
                $PostContent = $Post -Split "="
                [System.Reflection.Assembly]::LoadWithPartialName("System.Web") | out-null
                $PostName = [System.Web.HttpUtility]::UrlDecode($PostContent[0])
                $PostValue = [System.Web.HttpUtility]::UrlDecode($PostContent[1])

                if ($PostName.EndsWith("[]")) {
                    $PostName = $PostName.Substring(0,$PostName.Length-2)

                    if (!(New-Object PSObject -Property @{PostName=@()}).PostName) {
                        $Properties | Add-Member NoteProperty $Postname (@())
                        $Properties."$PostName" += $PostValue
                    } else {
                        $Properties."$PostName" += $PostValue
                    }
                } else {
                    $Properties | Add-Member NoteProperty $PostName $PostValue
                }
            }
        }
        $Properties | Add-Member Noteproperty NodePSPostStream $NodePSPostStream
        $Properties | Add-Member Noteproperty NodePSContentType $ContentType
		Write-Output $Properties
    }
}
