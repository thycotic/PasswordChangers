IAM Password Changer
====================

This will change the password for an IAM user using it's own Access Keys. This method will now work for password reset


| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | Any Supported |
| PowerShell | Windows Management Framework 3+ |

 #### Prerequisites: 
- AWS SDK installed on the Secret Server or Engine Machine
- Secret Server configured to execute PowerShell scripts
- Amazon account with IAM access keys

 #### Configuration

1. Add AWS-IAM-Password-Changer.ps1 and AWS-IAM-heartbeat.ps1 scripts to Secret Server:
 - **ADMIN** > **Scripts**
 
2. Create the templates:
 - Create a new Secret Template under **Admin** > **Secret Template** and call it **AWS IAM Account**
 - Add the following fields in order: Account, Username, Password, Notes. Make sure you select the correct field types from the drop down menu
 - Create a second template and call it **AWS IAM Access Key**
 - Add the followings fields in order: AccessKey, SecretKey, Username(to help easily identify the keys)

3. Configure the Password Changer: 
 - **ADMIN** > **Remote Password Changing** > **Configure Password Changers** >
 - Click on New to create a new Password changer
 - Select "PowerShell Script" from the drop down
 - Name your new password changer
 - Select your heartbeat script fro the verify commands, and the password changer for the change commands
 - In the Scripts Args for heartbeat enter: $ACCOUNT $USERNAME $PASSWORD
 - In the Scripts Args for Password change enter: $NEWPASSWORD $PASSWORD $[1]$ACCESSKEY $[1]$SECRETKEY
 - Click Save to finish
 - Go back to the **AWS IAM Account** template and click on configure Password Changers
 - Enable Remote Password Changing checkbox and heartbeat. Leave the default settings or change
 - Set the "Password Type to use" to your AWS password changer (whatever you chose to name it from the previous step)
 - Map the fields: Domain is mapped to Account, Password is mapped to Password, and User name to Username

4. Now to change passwords:
 - Create a new Secret using the IAM Account template, fill the fields
 - Create another Secret using the IAM Access Key template and fill the fields
 - On the IAM account Secret, click on **Remote Password Changing** > **Edit**
 - Select a Privileged Account Secret to run PowerShell under "Run PowerShell Using"
 - Below where it says " No Secret Selected" Click on it and Select the Access Key Secret
 - Save
