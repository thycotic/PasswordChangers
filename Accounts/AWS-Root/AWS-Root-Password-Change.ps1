$email=""
$password=""
$newPassword=""
$loginUrl = "https://signin.aws.amazon.com/signin?client_id=arn%3Aaws%3Aiam%3A%3A015428540659%3Auser%2Fhomepage&redirect_uri=https%3A%2F%2Fconsole.aws.amazon.com%2Fconsole%2Fhome%3Fstate%3DhashArgs%2523%26isauthcode%3Dtrue&page=resolve"
#initiate internet explorer object
$ie = New-Object -ComObject "internetexplorer.application"
$ie.visible = $true
$ie.navigate($loginUrl)
try
    {
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
        $document=$ie.Document
        #Enter Username
        $document.GetElementById("resolving_input").value=$email
        ($document.getElementsByTagName("button") | where {$_.innerText -eq "Next"}).click();
        Start-Sleep 5
        #Enter Password
        ($document.GetElementById("ap_password")| select -First 1).value=$password;
        #Sign In
        ($document.GetElementById("signInSubmit-input")).click();
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
        #navigate to password change page
        ($document.GetElementById("aws-security-credentials")).click()
        Start-Sleep 5
        ($document.getElementsByTagName("a") | where {$_.textContent -eq "Click here"}).click();
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
        ($document.getElementById("cnep_1A_change_password_button-input")).click();
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2;}
        #start changing password
        ($document.getElementById("ap_password")).value=$password
        ($document.getElementById("ap_password_new")).value=$newPassword
        ($document.getElementById("ap_password_new_check")).value=$newPassword
        ($document.getElementById("cnep_1D_submit_button-input")).click();
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2;}
        ($document.getElementById("cnep_1A_done_button")).click();
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2;}
        #check if change successful
        if($ie.LocationURL -like "*security_credential*")
            {
                $document=$ie.Document
                ($document.GetElementById("aws-console-logout")).click();
                return $true
            }
    }
catch
    {
        throw 'Error "{0}"' -f $_
    }

finally
    {
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2;}
        $ie.Quit();
    }
