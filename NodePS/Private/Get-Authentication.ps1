# NodePS Server Authentication Module
function Get-Authentication {
    param (
        [Parameter(
            Mandatory = $true)]
        $Context,

        [Parameter(
            Mandatory = $true)]
        $BasicAuthentication,

        [Parameter(
            Mandatory = $true)]
        $WindowsAuthentication
    )
	# Basic Authentication

	if ($BasicAuthentication -eq "On") {
		$Identity = $Context.User.Identity
		$NodePSUserName = $Identity.Name
		$NodePSUserPassword = $Identity.Password
	}

	# Windows Authentication
	if ($WindowsAuthentication -eq "On") {
		$Identity = $Context.User.Identity
		$NodePSUserName = $Identity.Name
        $NodePSUserPassword = ""
	}

    @($Identity,$NodePSUserName,$NodePSUserPassword)
}

