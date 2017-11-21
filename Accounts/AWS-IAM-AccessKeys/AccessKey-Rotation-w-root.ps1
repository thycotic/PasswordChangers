$RootAccessKey= $args[0]
$RootSecretKey= $args[1]
$IAMUSER= $args[2]
$AccessKey= $args[3]
Set-AWSCredentials -AccessKey $RootAccessKey -SecretKey $RootSecretKey

#Search For Inactive Keys and delete them
try{
$InactiveKeys= Get-IAMAccessKey -UserName $IAMUSER | Where-Object {$_.Status -match 'Inactive'}

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

#Set Secret Server API call variables. Comment if using integrated authentication

#region Authentication
$ssUrl = ""
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
#endregion

##### Uncomment below if you're using Integrated Authentication #####
#$winAuthApi="$ssUrl/winauthwebservices/api/v1"

#Pull the Secret From Secret Server. Comment if you're using Integrated Authentication for API
try
{
$getSecret = Invoke-RestMethod -Uri ($api+"/secrets/"+$args[6]) -Headers $headers -Method Get
}

##### Uncomment below if you're using integrated authentication for API calls. Refer to readme.md for instructions ####
<#
try{
    $getSecret = Invoke-RestMethod -Uri ($winAuthApi+"/secrets/"+$args[6]) -UseDefaultCredentials -Method Get
    }
#>
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


#Push the new keys to Secret Server. Comment if using Integrated Windows Authentication
try
{
Invoke-RestMethod -Uri ($api+"/secrets/"+$args[6]) -Body $arguments -Method Put -Headers $headers -ContentType "application/json"
}

#Uncomment below if you're using integrated authentication for API calls. Refer to readme.md for instructions
<#
try{
    Invoke-RestMethod -Uri ($winAuthApi+"/secrets/"+$args[6]) -Body $arguments -Method Put -UseDefaultCredentials -ContentType "application/json"
    }
#>

catch{
        $result = $_.Exception.Response.GetResponseStream();
        $reader = New-Object System.IO.StreamReader($result);
        $reader.BaseStream.Position = 0;
        $reader.DiscardBufferedData();
        $responseBody = $reader.ReadToEnd() | ConvertFrom-Json
        throw "Update Secret Error: $($responseBody.errorCode) - $($responseBody.message)"
        return;
}
