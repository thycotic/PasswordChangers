try {
  	Edit-IAMPassword  -NewPassword $args[2] -OldPassword $args[3] -accessKey $args[4] -secretKey $args[5] -ErrorAction Stop
}
catch [Exception] {
	throw "Could not change password: $($_.Exception.Message)"
}