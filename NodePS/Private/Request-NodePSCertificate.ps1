function Request-NodePSCertificate {

<#
    .SYNOPSIS

        Function to create NodePS Certificate request

    .EXAMPLE

        Request-NodePSCertificate

#>

	$SSLSubject = "NodePSServer"
	$SSLName = New-Object -com "X509Enrollment.CX500DistinguishedName.1"
	$SSLName.Encode("CN=$SSLSubject", 0)
	$SSLKey = New-Object -com "X509Enrollment.CX509PrivateKey.1"
	$SSLKey.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
	$SSLKey.KeySpec = 1
	$SSLKey.Length = 2048
	$SSLKey.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
	$SSLKey.MachineContext = 1
	$SSLKey.ExportPolicy = 1
	$SSLKey.Create()
	$SSLObjectId = New-Object -com "X509Enrollment.CObjectIds.1"
	$SSLServerId = New-Object -com "X509Enrollment.CObjectId.1"
	$SSLServerId.InitializeFromValue("1.3.6.1.5.5.7.3.1")
	$SSLObjectId.add($SSLServerId)
	$SSLExtensions = New-Object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
	$SSLExtensions.InitializeEncode($SSLObjectId)
	$SSLCert = New-Object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
	$SSLCert.InitializeFromPrivateKey(2, $SSLKey, "")
	$SSLCert.Subject = $SSLName
	$SSLCert.Issuer = $SSLCert.Subject
	$SSLCert.NotBefore = Get-Date
	$SSLCert.NotAfter = $SSLCert.NotBefore.AddDays(1825)
	$SSLCert.X509Extensions.Add($SSLExtensions)
	$SSLCert.Encode()
	$SSLEnrollment = New-Object -com "X509Enrollment.CX509Enrollment.1"
	$SSLEnrollment.InitializeFromRequest($SSLCert)
	$SSLEnrollment.CertificateFriendlyName = 'NodePSServer SSL Certificate'
	$SSLCertdata = $SSLEnrollment.CreateRequest(0)
	$SSLEnrollment.InstallResponse(2, $SSLCertdata, 0, "")
}
