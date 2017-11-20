$RootAccessKey= $args[0]
$RootSecretKey= $args[1]
$IAMUSER= $args[2]
$AccessKey= $args[3]
Set-AWSCredentials -AccessKey $RootAccessKey -SecretKey $RootSecretKey

#Search For Inactive Keys and delete them
try{
$InactiveKeys= Get-IAMAccessKey -UserName $IAMUSER | Where {$_.Status -match 'Inactive'}

if ($InactiveKeys.length -ne 0){
    ForEach($InactiveKey in $InactiveKeys){
        Remove-IAMAccessKey -AccessKeyId $InactiveKeys.AccessKeyId -Force
}
}
else {
    Write-Debug "No inactive keys"
}
}

catch [Exception]{
    throw "Remove inactive key error: " + ($Error[0].Exception.Message)
    break;

}
#Disabling and creating new keys
try
{
Update-IAMAccessKey -AccessKeyId $AccessKey -UserName $IAMUSER -Status Inactive
$NewKeys = New-IAMAccessKey -UserName $IAMUSER
$NewAccessKey = $NewKeys.AccessKeyId
$NewSecretKey = $NewKeys.SecretAccessKey

}

catch [Exception]
{
    throw "Create new key error: " + ($Error[0].Exception.Message)
    break;
}

#Set Secret Server API call variables
$ssUrl = "https://vault"
$api ="$ssUrl/api/v1"
$ssUsername = $args[4]
$ssPassword = $args[5]
$creds = @{
            username=$ssUsername
            password=$ssPassword
            grant_type="password"
            
            };

#Authenticate to Secret Server
try{
$authenticate= Invoke-RestMethod "$ssURL/oauth2/token" -Method Post -Body $creds
$token= $authenticate.access_token
}

catch{
        $result = $_.Exception.Response.GetResponseStream();
        $reader = New-Object System.IO.StreamReader($result);
        $reader.BaseStream.Position = 0;
        $reader.DiscardBufferedData();
        $responseBody = $reader.ReadToEnd() | ConvertFrom-Json
        throw "REST Authentication Error: $($responseBody.errorCode) - $($responseBody.message)"
        return;
}


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $token")

#Pull the Secret From Secret Server
try
{
$getSecret = Invoke-RestMethod -Uri ($api+"/secrets/"+$args[6]) -Headers $headers -Method Get
}
catch{
        $result = $_.Exception.Response.GetResponseStream();
        $reader = New-Object System.IO.StreamReader($result);
        $reader.BaseStream.Position = 0;
        $reader.DiscardBufferedData();
        $responseBody = $reader.ReadToEnd() | ConvertFrom-Json
        throw "Get Secret Error: $($responseBody.errorCode) - $($responseBody.message)"
        return;
}
#set the old Secret values to the new keys
$getSecret.items[0].itemValue = $NewAccessKey
$getSecret.items[1].itemValue = $NewSecretKey
$arguments = $getSecret | ConvertTo-Json


#Push the new keys to Secret Server
try
{
$updateSecret = Invoke-RestMethod -Uri ($api+"/secrets/"+$args[6]) -Body $arguments -Method Put -Headers $headers -ContentType "application/json"
}

catch{
        $result = $_.Exception.Response.GetResponseStream();
        $reader = New-Object System.IO.StreamReader($result);
        $reader.BaseStream.Position = 0;
        $reader.DiscardBufferedData();
        $responseBody = $reader.ReadToEnd() | ConvertFrom-Json
        throw "Update Secret Error: $($responseBody.errorCode) - $($responseBody.message)"
        return;
}