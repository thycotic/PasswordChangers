$loginUrl = $args[0]
#initiate internet explorer object
$ie = New-Object -ComObject "internetexplorer.application"
$ie.visible = $true
$ie.navigate2($loginUrl)
#wait untill IE is ready
while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
$document=$ie.Document
#click on the change password link
($document.getElementsByTagName("a") | where {$_.innerText -eq "Change Password"}).click();
#get the last form fields that are relevant to password changing
$fields= $document.getElementsByTagName("input") | Select -Last 4
#pass the values to the form fields
$fields[0].value=$args[1] #username
$fields[1].value=$args[2] #old password
$fields[2].value=$args[3] #new password
$fields[3].value=$args[4] #verify password
#submit the password change
($document.getElementsByTagName("button") | where {$_.innerText -eq "Submit"}).click();
