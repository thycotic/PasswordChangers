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
$loginUrl =$args[2]
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
        #get the first  form fields that are relevant to sign in
        $document.GetElementById("resolving_input").value=$email
        #pass the values to the form fields
        ($document.getElementsByTagName("button") | where {$_.innerText -eq "Next"}).click();
        Start-Sleep -Seconds 5;
        #enter password
        ($document.GetElementById("ap_password")| select -First 1).value=$password;
        #Sign In
        ($document.GetElementById("signInSubmit-input")).click();
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
        if($ie.LocationURL -like "*https://console.aws.amazon.com*")
            {
                ($document.GetElementById("aws-console-logout")).click();
                return $true
            }
        else
            {
                throw "Error Heartbeating account"
            }
    }
catch
    {

        throw 'Error "{0}"' -f $_

    }
finally
    {
        while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
        $ie.Quit();
    }