function New-AccessKeys {
    param(
        [CmdletBinding(DefaultParameterSetName="win_auth")]
        [Parameter(Mandatory=$true)]
        [string]$AccessKey,
        [Parameter(Mandatory=$true)]
        [string]$SecretKey,
        [parameter(Mandatory=$true)]
        [string]$AWSUserName,
        [parameter(Mandatory=$true)]
        [string]$Url,
        [parameter(Mandatory=$true)]
        [string]$SecretId,
        [parameter(ParameterSetName="win_auth")]
        [switch]$UseDefaultCredentials,
        [parameter(Mandatory=$true,ParameterSetName="token_auth")]
        [string]$UserName,
        [parameter(Mandatory=$true,ParameterSetName="token_auth")]       
        [string]$Password
    )
    Begin {
        function Write-WebError([string]$Prefix){    
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            throw "$($Prefix): $($responseBody)"
        }
        #set SS url and creds
        if($PSCmdlet.ParameterSetName -eq "token_auth") {
            $api ="$Url/api/v1/secrets/$SecretId"
            $creds = @{
                username = $UserName
                password = $Password
                grant_type = "password"
            }
            #Authenticate to Secret Server
            try {
                $token = (Invoke-RestMethod "$Url/oauth2/token" -Method Post -Body $creds -ErrorAction Stop).access_token
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
        elseif($PSCmdlet.ParameterSetName -eq "win_auth") {
            $api="$Url/winauthwebservices/api/v1/secrets/$SecretId"
            $params = @{
                Uri = $api
                ContentType = "application/json"
                UseDefaultCredentials=$true
            }
        }
        #remove any inactive keys
        try {
            Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey
            $inactiveKeys= @(Get-IAMAccessKey -UserName $AWSUserName | Where-Object {$_.Status -match 'Inactive'})
            if ($inactiveKeys.length -ne 0){
                $inactiveKeys.foreach({
                    Remove-IAMAccessKey -AccessKeyId $_.AccessKeyId -ErrorAction Stop -Force
                });
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
            $newKeys = New-IAMAccessKey -UserName $AWSUserName -ErrorAction Stop
        }
        catch {
            throw "Create key error: $($_.Exception.Message)"
        }
        #push the Key to Secret Server
        try {
            $getSecret = Invoke-RestMethod -Method Get @params -ErrorAction Stop
            $getSecret.items[0].itemValue = $($newKeys.AccessKeyId)
            $getSecret.items[1].itemValue = $($newKeys.SecretAccessKey)
            $body = $getSecret | ConvertTo-Json
        }
        catch {
            Write-WebError -Prefix "Get secret error"
        }
        try {
            Invoke-RestMethod -Method Put -Body $body @params -ErrorAction Stop| Out-Null
        }
        catch {
            #remove the new generated key if there is an error updating the Secret to avoice qouta error
            Start-Sleep 10
            Remove-IAMAccessKey -AccessKeyId $newKeys.AccessKeyId -ErrorAction Stop -Force
            Write-WebError -Prefix "Update secret error"
        }
        try {
            #Set the previous access key to inactive
            Start-Sleep 10
            Update-IAMAccessKey -AccessKeyId $AccessKey -Status Inactive -ErrorAction Stop
        }
        catch {
            throw "Set key inactive error: $($_.Exception.Message)"
        }
    }
}