function Set-AccessKeys {
    param(
        [CmdletBinding()]
        [Parameter(Mandatory=$true)]
        [string]
        $AccessKey,
        [Parameter(Mandatory=$true)]
        [string]
        $SecretKey,
        [parameter(Mandatory=$true)]
        [string]
        $AWSUserName,
        [string]
        $Url,
        [string]
        $SecretId,
        [parameter(ParameterSetName="TokenAuth")]
        [switch]
        $UseTokenAuth,
        [parameter(Mandatory=$true,ParameterSetName="TokenAuth")]
        [string]$UserName,
        [parameter(Mandatory=$true,ParameterSetName="TokenAuth")]        
        [string]$Password
    )
    Begin{
        function Write-WebError([string]$Prefix){    
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            throw "$($Prefix): $($responseBody)"
        }
        #set SS url and creds
        if($UseTokenAuth) {
            $api ="$Url/api/v1/secrets/$SecretId"
            $creds = @{
                username = $UserName
                password = $Password
                grant_type = "password"
            }
            #Authenticate to Secret Server
            try {
                $token = (Invoke-RestMethod "$Url/oauth2/token" -Method Post -Body $creds).access_token
                $headers = @{Authorization="Bearer $token"}
                $params = @{
                    Header = $headers
                    Uri = $api
                    ContentType = "application/json"
                }
            }
            catch {
                Write-WebError -Prefix "Authentication Error"
            }
        }
        else{
            $api="$Url/winauthwebservices/api/v1/secrets/$SecretId"
            $params = @{
                Uri = $api
                ContentType = "application/json"
            }
        }
        #remove inactive keys
        try {
            Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey
            $inactiveKeys= Get-IAMAccessKey -UserName $AWSUserName | Where-Object {$_.Status -match 'Inactive'}
            if ($inactiveKeys.length -ne 0){
                $inactiveKeys.foreach({
                    Remove-IAMAccessKey -AccessKeyId $inactiveKeys.AccessKeyId -Force
                })
            }
            else {
                Write-Debug "No inactive keys"
            }
        }
        catch [Exception] {
            throw "Remove inactive key error: $($_.Exception.Message)"      
        }
    }
    Process {
        #Create the keys
        try {
            $NewKeys = New-IAMAccessKey -UserName $AWSUserName
            $NewAccessKey = $NewKeys.AccessKeyId
            $NewSecretKey = $NewKeys.SecretAccessKey
        }
        catch {
            throw "Create key error: $($_.Exception.Message)"
        }
        #push the Key to Secret Server
        try{
            $getSecret = Invoke-RestMethod -Method Get @params
        }
        catch {
            Write-WebError -Prefix "Get secret error"
        }
        $getSecret.items[0].itemValue = $NewAccessKey
        $getSecret.items[1].itemValue = $NewSecretKey
        $body = $getSecret | ConvertTo-Json
        try {
            Invoke-RestMethod -Method Put -Body $body @params
        }
        catch {
            Write-WebError -Prefix "Update secret error"
        }
        Start-Sleep 10
        try {
            Update-IAMAccessKey -AccessKeyId $AccessKey -Status Inactive
        }
        catch {
            throw "Set key inactive error: $($_.Exception.Message)"
        }
    }
}