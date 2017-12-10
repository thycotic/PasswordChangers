$dllPath="C:\Program Files (x86)\Microsoft.NET\Primary Interop Assemblies\Microsoft.mshtml.dll"
try
    {
        $checkDll=Get-Item -Path $dllPath -ErrorAction SilentlyContinue
        if($checkDll.Exists)
            {
                Add-Type -Path $dllPath
            }
        else
            {
                throw "Could not load Microsoft.mshtml.dll please make sure that it exist in C:\Program Files (x86)\Microsoft.NET\Primary Interop Assemblies\"
            }
     }
catch
    {
        throw "Error: " + $Error[0].Exception.Message
    }
$email=$args[0]
$password=$args[1]
$newPassword=$args[2]
$loginUrl = $args[3]
#initiate internet explorer object
$ie = New-Object -ComObject "internetexplorer.application"
$ie.visible = $false
$ie.navigate($loginUrl)
try
    {
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
        if($ie.LocationURL -like "*awsemail*")
            {
                $document=$ie.Document
                ($document.GetElementById("aws-login-switchaccount-link")).click();
            }
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
        $document=$ie.Document
        #Enter Username
        $document.GetElementById("resolving_input").value=$email
        ($document.getElementsByTagName("button") | where {$_.innerText -eq "Next"}).click();
        Start-Sleep 3
        #Enter Password
        ($document.GetElementById("ap_password")| select -First 1).value=$password;
        #Sign In
        ($document.GetElementById("signInSubmit-input")).click();
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
        #navigate to password change page
        ($document.GetElementById("aws-security-credentials")).click()
        Start-Sleep 3
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