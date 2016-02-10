function Get-MimeType {

<#
    .SYNOPSIS

        Function to get mime types

    .EXAMPLE

        Get-MimeType -Extension ".jpg"

#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (

    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Extension')]
    [string]$Extension
)

	switch ($Extension) {
        .ps1 {"text/ps1"}
        .psjson {"text/psjson"}
        .psxml {"text/psxml"}
		.html {"text/html"}
		.htm {"text/html"}
		.css {"text/css"}
		.jpeg {"image/jpeg"}
		.jpg {"image/jpeg"}
		.gif {"image/gif"}
		.ico {"image/x-icon"}
		.flv {"video/x-flv"}
		.swf {"application/x-shockwave-flash"}
		.js {"text/javascript"}
		.txt {"text/plain"}
		.rar {"application/octet-stream"}
		.zip {"application/x-zip-compressed"}
		.rss {"application/rss+xml"}
		.xml {"text/xml"}
		.pdf {"application/pdf"}
		.png {"image/png"}
		.mpg {"video/mpeg"}
		.mpeg {"video/mpeg"}
		.mp3 {"audio/mpeg"}
		.oga {"audio/ogg"}
		.spx {"audio/ogg"}
		.mp4 {"video/mp4"}
		.m4v {"video/m4v"}
		.ogg {"video/ogg"}
		.ogv {"video/ogg"}
		.webm {"video/webm"}
		.wmv {"video/x-ms-wmv"}
		.woff {"application/x-font-woff"}
		.eot {"application/vnd.ms-fontobject"}
		.svg {"image/svg+xml"}
		.svgz {"image/svg+xml"}
		.otf {"font/otf"}
		.ttf {"application/x-font-ttf"}
		.xht {"application/xhtml+xml"}
		.xhtml {"application/xhtml+xml"}
		default {"text/html"}
	}
}

