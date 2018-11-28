function Verify-AccessKeys {
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
    Begin{
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
                throw  "$url | $username | Authentication Error $($_.Exception.Message)"
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
    }
    Process {
        #Verify the Keys using Direct Script Inputs
        try
        {
            Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey 
            $Verify= Get-IAMAccessKey -UserName $AWSUserName 
                If ($Verify.AccessKeyId -like "*$AccessKey*" -and $Verify.status -match 'Active')
                {
                    Return $TRUE
                }
        
        }
        catch [Exception]
        {
            try {
                $getSecret = Invoke-RestMethod -Method Get @params -ErrorAction Stop
                $AccessKey = $getSecret.items[0].itemValue 
                $SecretKey = $getSecret.items[1].itemValue 
            }
            catch {
                throw "Get secret error $($_.Exception.Message)"
            }
            
            try
            {
                Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey
                $Verify= Get-IAMAccessKey -UserName $AWSUserName -ErrorAction Stop 
                    if ($Verify.AccessKeyId -like "*$AccessKey*" -and $Verify.status -match 'Active') 
                    {
                       Return $TRUE
                    }
                    
            
            }
            catch [Exception]
            {
                Throw "Could not Verify Access Keys. Check with your AWS Administrator" +$Error[0].Exception.Message
                return $False
            }
        }
        
    }
}


Verify-AccessKeys -AccessKey $args[0] -SecretKey $args[1] -AWSUserName $args[2] -SecretId $args[3] -Url "https://SSURL" -UseDefaultCredentials
#Verify-AccessKeys -AccessKey $args[0] -SecretKey $args[1] -AWSUserName $args[2] -SecretId $args[3] -Url "https://SSURL" -UserName $args[4] -Password $args[5]
