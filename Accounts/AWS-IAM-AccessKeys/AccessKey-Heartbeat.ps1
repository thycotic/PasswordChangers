$AccessKey= $args[0]
$SecretKey= $args[1]
$IAMUSER= $args[2]
try
{
    Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey
    $Verify= Get-IAMAccessKey -UserName $IAMUSER
        If ($Verify.AccessKeyId -like "*$AccessKey*" -and $Verify.status -match 'Active') 
        {
            $TRUE
        }

}
catch [Exception]
{
    $False
    Throw "Could not Verify Access Keys. Check with your AWS Administrator" +$Error[0].Exception.Message
}