Function Set-AXLSynceAccount {
    param(
        [string]$WsdlPath,
        [string]$Url,
        [string]$UserName,
        [securestring]$Password,
        [string]$LdapName,
        [string]$LdapDN,
        [string]$LdapPassword,
        [switch]$UntrustedCertificate
    )
    begin {
        #create a credential object to authenticate to AXL
        $creds = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $Password
        
        #generate the WSDL and point to the CUCM URL
        $proxy = New-WebServiceProxy -Uri  $WsdlPath -Credential $creds -Namespace AXL
        $proxy.Url = $Url

        #creating an LDAP update request
        $updateLdapReq = New-Object -TypeName "AXL.updateLdapDirectoryReq"

        #create an LDAP sync request
        $syncReq = New-Object -TypeName "AXL.DoLdapSyncReq"

        #create an LDAP sync status request
        $getSyncStatus = New-Object -TypeName "AXL.getLdapSyncStatusReq"
        
        if($UntrustedCertificate) {
            add-type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
                public bool CheckValidationResult(
                    ServicePoint srvPoint, X509Certificate certificate,
                    WebRequest request, int certificateProblem) {
                    return true;
                }
            }
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
            [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
            [Net.ServicePointManager]::Expect100Continue = $false
        }
    }
    process {

        #update LDAP account name and password
        $updateLdapReq.Item = $LdapName
        $updateLdapReq.ldapDn = $LdapDN
        $updateLdapReq.ldapPassword = $LdapPassword
        try{
            $proxy.updateLdapDirectory($updateLdapReq)
        }
        catch{
            throw "Update ldap error: $($_.Exception.Message)"
        }

        #initiate LDAP Sync
        $syncReq.Item = $LdapName
        $syncReq.sync = $true
        try {
            $doLdapSync=$proxy.doLdapSync($syncReq)
        }
        catch {
            throw "Initiate Ldap sync error: $($doLdapSync.return)"
        }
        
        #check the sync status was successful
        $getSyncStatus.Item = $LdapName
        try {
            $syncStatus = $proxy.getLdapSyncStatus($getSyncStatus)
        }
        catch {
            throw $_.Exception.Message
        }

        #check if sync was successful
        if($syncStatus.return -eq "Sync is performed successfully"){
            return $true
        }
        else {
            throw "Ldap sync error: $($syncStatus.return)"
        }
    }#end process block
}# end function block
Set-AXLSynceAccount -WsdlPath $args[0] -Url $args[1] -UserName $args[2] -Password (ConvertTo-SecureString -AsPlainText $args[3] -Force) -LdapName $args[4] -LdapDN "$($args[5])@$($args[4])" -LdapPassword $args[6] -UntrustedCertificate