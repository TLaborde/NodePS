NodePS
=============

This is a WebServer written in PowerShell, as a module, which is able to read and execute PowerShell code.

* Thanks to Yusuf Ozturk of [PoSH Server](http://www.poshserver.net/) fame for the original codebase
* Thanks to [RamblingCookieMonster](https://github.com/RamblingCookieMonster) for his blog articles about PowerShell modules and about contributing
* Thanks to my teammates and my bosses, for the feedbacks and support

Caveats:

* Requires Powershell v4 minimum
* No testing published. Maybe one day when I get around reading on Pester. Contributions welcome!
* The WebServer use a .Net object that requires local administrator rights. Please be careful and maybe put it behind a reverse proxy (IIS can do it).
* Naming conventions and coding style subject to change. Suggestions welcome!

#Functionality

* Webserver allowing to publish script written in PowerShell. Like NodeJS for JavaScript. But multithreaded out-off-the-box.
* Basic Auth, Windows Auth (local or domain)
* Can be used to server static files (for production, it's better to reverse proxy and use IIS for static content)
* Support JSON and XML headers in response
* "Safe" threads running the PowerShell script
* Shared variables between threads available (for session or other)
* IP filtering, content blocking

#Instructions

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the NodePS folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

# Import the module. You need to be in an elevated shell.
    Import-Module NodePS    #Alternatively, Import-Module \\Path\To\NodePS

# Get public command in the module
    Get-Command -Module NodePS

# Get help for a command
    Get-Help Start-NodePSServer -Full

# Start the WebServer with all default settings
    Start-NodePSServer

# Start the WebServer on https with self-generated certificate
   Start-NodePSServer -SSL -SSLIP "127.0.0.1" -SSLPort 443
   
# Start the WebServer as a Scheduled Task
    Start-NodePSServer -asJob
 
 ```
 