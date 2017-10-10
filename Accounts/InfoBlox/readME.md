InfoBlox Changer
====================

This will change the password for infoblox local accounts using their API. This was was tested on another clients environment for a specific use case.


| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | Any Supported |
| Infoblox Virtual Appliance | API v2.6 |
| PowerShell | Windows Management Framework 3+ |

 #### Prerequisites: 
- Secret Server configured to execute PowerShell scripts
- InfoBlox virtual or physical appliance

 #### Configuration

1. Add infoblox-Password-Changer.ps1 and infoblox-heartbeat.ps1 scripts to Secret Server:
 - **ADMIN** > **Scripts**
 
2. Create the templates:
 - Create a new Secret Template under **Admin** > **Secret Template** and call it **infoBlox**
 - Add the following fields in order: Url, Username, Password, Notes. Make sure you select the correct field types from the drop down menu

3. Configure the Password Changer: 
 - **ADMIN** > **Remote Password Changing** > **Configure Password Changers** >
 - Click on New to create a new Password changer
 - Select "PowerShell Script" from the drop down
 - Name your new password changer
 - Select your heartbeat script fro the verify commands, and the password changer for the change commands
 - In the Scripts Args for heartbeat enter: $USERNAME $PASSWORD $URL
 - In the Scripts Args for Password change enter: $[1]$USERNAME $[1]$PASSWORD $URL $USERNAME
 - Click Save to finish
 - Go back to the **infoBlox** template and click on configure Password Changers
 - Enable Remote Password Changing checkbox and heartbeat. Leave the default settings or change
 - Set the "Password Type to use" to your infoblox password changer (whatever you chose to name it from the previous step)
 - Map the fields: Domain is mapped to Url, Password is mapped to Password, and User name to Username

4. Now to change passwords:
 - Create a new Secret using the infoblox template, fill the fields
 - Create another Secret using the same template and fill the fields, this will be your privileged infoblox account
 - The privileged Secret can be used to change other account's passwords, or it's own account
 - On the non privileged Secret, click on **Remote Password Changing** > **Edit**
 - Select a Privileged Account Secret to run PowerShell under "Run PowerShell Using". Typically a domain account
 - Below where it says " No Secret Selected" Click on it and Select the privileged infoblox account
 - Save