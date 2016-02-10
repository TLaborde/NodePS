function New-NodePSTimeStamp {

<#
    .SYNOPSIS

        Function to generate time stamp

    .EXAMPLE

        New-NodePSTimeStamp

#>

    Get-Date -Format "HHmmssfff"
}
