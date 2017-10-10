#Needed if the InfoBlox cert isn't trusted
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
$userName=$args[0]
$password= ConvertTo-SecureString -AsPlainText $args[1] -Force
$creds=New-Object System.Management.Automation.PSCredential -ArgumentList $userName, $password
$url=$args[2]
$api="/wapi/v2.6/adminuser"
$filter="?name="+$user
$uri=$url+$api+$filter
try {$req=Invoke-RestMethod -Uri $uri -Credential $creds}
catch [System.Net.WebException]
{
Write-Debug "----- Exception -----"
Write-Debug  $_.Exception
Write-Debug  $_.Exception.Response.StatusCode
Write-Debug  $_.Exception.Response.StatusDescription
$result = $_.Exception.Response.GetResponseStream()
$reader = New-Object System.IO.StreamReader($result)
$reader.BaseStream.Position = 0
$reader.DiscardBufferedData()
$responseBody = $reader.ReadToEnd()
}
if($responseBody.Length -eq 0)
{return $true}
else
{
    throw "Heartbeat Failed: "+$responseBody.Error
}