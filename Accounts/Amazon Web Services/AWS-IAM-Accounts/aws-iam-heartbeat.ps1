#Initial wait time is important to validate a newly changed password.
Start-Sleep 10
$dllPath="C:\Program Files (x86)\Microsoft.NET\Primary Interop Assemblies\Microsoft.mshtml.dll"
try {
    $checkDll=Get-Item -Path $dllPath -ErrorAction SilentlyContinue
    if($checkDll.Exists) {
        Add-Type -Path $dllPath
    }
    else {
        throw "Could not load Microsoft.mshtml.dll please make sure that it exist in C:\Program Files (x86)\Microsoft.NET\Primary Interop Assemblies\"
    }
}
catch {
    throw "Error loading DLL: $($_.Exception.Message)"
}
$account = $args[0]
$username = $args[1]
$password = $args[2]
$loginUrl = "https://${account}.signin.aws.amazon.com/console"
#initialize browser
$ie = New-Object -ComObject "internetexplorer.application"
$ie.visible = $false
$ie.navigate($loginUrl)
try {
    #wait for browser idle
    while ($ie.Busy -eq $true) { 
        Start-Sleep -Seconds 1; 
    }
    #login
    $Doc=$ie.Document
    ($Doc.getElementById("account") | Select -First 1).value = $account
    ($Doc.getElementById("username") | Select -First 1).value = $username
    ($Doc.getElementById("password") | Select -First 1).value = $password
    ($Doc.getElementById("signin_button") | Select -first 1).click()
    Start-Sleep 5
    if($Doc.getElementById("main_message").textContent -like "*Your authentication information is incorrect*") {
        while($ie.Busy -eq $true) { 
            Start-Sleep -Seconds 1;
        }
        throw $Doc.getElementById("main_message").textContent
    }
    else {
        return $true
    }
}
catch {
    throw $_.Exception.Message
}
Finally {
    $ie.Quit()
}