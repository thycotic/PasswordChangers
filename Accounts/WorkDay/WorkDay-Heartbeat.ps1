$loginUrl = $args[0]
#initiate internet explorer object
$ie = New-Object -ComObject "internetexplorer.application"
$ie.visible = $false
$ie.navigate2($loginUrl)
#wait untill IE is ready
while ($ie.Busy -eq $true) { Start-Sleep -Seconds 2; }
$document=$ie.Document
#get the first two form fields that are relevant to sign in
$fields= $document.getElementsByTagName("input") | Select -First 2
#pass the values to the form fields
$fields[0].value=$args[1] #username
$fields[1].value=$args[2] #password
#Sign In
($document.getElementsByTagName("button") | where {$_.innerText -eq "Sign In"}).click();
