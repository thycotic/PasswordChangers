# Set initial status to fail until proven to succeed.
$exit_status = -1

# TODO: Sanitize these inputs!
# Transfer variables from call.
$DOMAIN = $Args[0]
$OKTA_API_KEY = $Args[1]
$USERNAME = $Args[2]
$PASSWORD = $Args[3]
$PORT = '443'


#Enter a key manually here if not specifying in the parameters.
#$OKTA_API_KEY = ''

try {
    # Use DNS resolution to ensure a valid domain name was entered, fastest and easiest way to check.
    $DNSOutput = Resolve-DnsName -Name ${DOMAIN} -DnsOnly
    if(${DNSOutput}.Name.GetType().FullName -match "System.String") {
        $ResolvedName = ${DNSOutput}.Name
    }
    else {
        $ResolvedName = ${DNSOutput}.Name[0]
    }
}
catch {
    Write-Error "FATAL: Cannot resolve the domain name, please check the domain name parameter. $($PSItem.Execption.GetType())"
    $PSItem.Exception | Get-Member | Write-Debug
    throw $PSItem
}

# Set system configuration for secure communications.
# [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True } # DO NOT Validate SSL Cert to trust store. (For Self Signed certs and testing only)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; # Require TLS 1.2

$cred= @{
    username = "${USERNAME}"
    password = "${PASSWORD}"
    options = @{
        multiOptionalFactorEnroll = "false"
        warnBeforePasswordExpired = "false"
    }
}

$auth = $cred | ConvertTo-Json

# Compile the URL
$URL = "https://${ResolvedName}:${PORT}/api/v1/authn"

# Add the API key into the authentication header.
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization","SSWS ${OKTA_API_KEY}")

try {
    # -UserAgent 'ThycoticSecretServerPowerShell' -Body ${auth}
    $output = Invoke-RestMethod -Uri ${URL} -Method Post -Body ${auth} -ContentType 'application/json' -Headers ${headers}
}
catch [System.Net.WebException] {
    # Determine why login failed, make it a bit more user friendly and still provide detailed messages.
    # Reference: https://stackoverflow.com/questions/38419325/catching-full-exception-message
    if ( $PSItem.Exception.Response.StatusCode -match "BadRequest" ) {
        throw [System.Net.WebException]::new("Failure: Target account credentials are invalid or locked out.", $PSItem.Exception)
    }
    elseif ( $PSItem.Exception.Response.StatusCode -match "InternalServerError" ) {
        throw [System.Net.WebException]::new("Error: An Internal Server Error has occurred.", $PSItem.Exception)
    }
    elseif ( $PSItem.Exception.Response.StatusCode -match "Unauthorized" ) {
        throw [System.Net.WebException]::new("Failure: Target account or API credentials invalid.", $PSItem.Exception)
    }

    # Uncaught and unhandled and unknown exceptions get extra dump treatment.
    $PSitem.Exception.Response | Format-List * | Write-Debug
    Write-Error "Unable to retrieve session token: $($PSItem.ToString())"
    Write-Error "FATAL: Unknown API Exception Encountred $($PSItem.Exception.GetType())"
    $innerException = $PSItem.Exception.InnerExceptionMessage
    Write-Debug "Inner Exception: $innerException"
        $e = $_.Exception
        $msg = $e.Message
        while ($e.InnerException) {
          $e = $e.InnerException
          $msg += "`n" + $e.Message
        }
        Write-Error $msg
    $PSItem.Exception | Get-Member | Write-Debug
    
    throw $PSItem
}
catch {
    Write-Error "Double FATAL: Unhandled Exception Type of $($PSItem.Exception.GetType())"
    Write-Error $PSItem.ToString()
    $PSItem.Exception | Get-Member | Write-Debug
    throw $PSItem
}

$stateToken = ${output}.stateToken
$status = ${output}.status

if("${status}" -match "PASSWORD_EXPIRED" -Or "${status}" -match "PASSWORD_RESET" -Or "${status}" -match "PASSWORD_WARN") {
    $return_status = @{ "Status" = "Password Expired"; "stateToken" = "${stateToken}" }
    Write-Output ${return_status}
    $exit_status = 0
}
elseif("${status}" -match "SUCCESS") {
    $return_status = @{ "Status" = "Success"; "stateToken" = "${stateToken}" }
    Write-Output ${return_status}
    $exit_status = 0
}
elseif("${status}" -match "MFA_REQUIRED" -Or "${status}" -match "MFA_ENROLL") {
$return_status = @{ "Status" = "MFA Required"; "stateToken" = "${stateToken}" }
    Write-Output ${return_status}
    $exit_status = 0
}
else {
    Write-Output @{ "Status" = "Failure"; "SessionToken" = "" }
    # Any other status, count it as soft bad.
    # throw [System.ApplicationException]::new("Cannot parse authorization token.",$PSItem)
    $exit_status = 1;
}

exit $exit_status;