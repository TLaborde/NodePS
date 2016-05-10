# You can run commands as the user who is accessing your server using "Impersonation"
# Example: http://localhost:8080/example6.ps1

"You are running this command as the server user $([Security.Principal.WindowsIdentity]::GetCurrent().Name)<br />"

[System.Security.Principal.WindowsImpersonationContext]$Context = $Identity.Impersonate()

"You are running this command as the user accessing your site $([Security.Principal.WindowsIdentity]::GetCurrent().Name)<br />"

#Don't forget to undo the impersonation! You don't want the next guy to be executing any code as this guy.
$Context.Undo()

"You are running this command as as the server user $([Security.Principal.WindowsIdentity]::GetCurrent().Name)<br />"