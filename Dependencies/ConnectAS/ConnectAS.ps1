$scriptBlock=
{
param($filter,$domain, $username, $password)
Import-Module WebAdministration
$username=($domain+"\"+$username)
try
{
    Set-WebConfigurationProperty -Filter $filter -Name "userName" -Value $userName
    Set-WebConfigurationProperty -Filter $filter -Name "password" -Value $password
}
catch [Exception]
    {
        throw $_.Exception.Message
    }
}

$computerName = $args[0]
Invoke-Command -ComputerName $computerName -ScriptBlock $scriptBlock -ArgumentList $args[1], $args[2], $args[3],$args[4]