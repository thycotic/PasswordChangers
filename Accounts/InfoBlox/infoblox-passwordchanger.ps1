#needed in case the infoblox cert isn't trusted.
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
#Being Vars
$privuser=$args[0]
$privPass= ConvertTo-SecureString -AsPlainText $args[1] -Force
$creds=New-Object System.Management.Automation.PSCredential -ArgumentList $privuser, $privPass
$url=$args[2]
$url= $url+"/wapi/v2.6/"
$username=$args[3]
$filter="adminuser?name="
$searchUri=$url+$filter+$username

try {$req=Invoke-RestMethod -Uri $searchUri -Credential $creds}


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
$responseBody = $reader.ReadToEnd() #| ConvertFrom-Json
throw  $responseBody.Error +" - " +$responseBody.code
}

$json =@{
password=$args[4]
} | ConvertTo-Json 
$updateUri=$url+$req._ref
try{
$updatePassword=Invoke-RestMethod -Uri $updateUri -Body $json -Method Put -ContentType "application/json" -Credential $creds
}
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
$responseBody = $reader.ReadToEnd() | ConvertFrom-Json
throw  $responseBody.Error +" - " +$responseBody.code
}
if($responseBody.Error.Length -eq 0)
{Write-Debug "Password Changed Successfully"}