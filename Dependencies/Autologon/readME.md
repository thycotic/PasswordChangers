Autologon Dependency Changer
====================

This will push the password to an encrypted registry location


| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | Any Supported |
| PowerShell | Windows Management Framework 3+ |

#### Prerequisites: 
- Machines with Autologon preconfigured
- Powershell remoting enabled on these machines

#### Configuration

1. Add Autologon.ps1 script to Secret Server:
 - **ADMIN** > **Scripts**
 
2. Configure Dependency Changer: 
 - **ADMIN** > **Remote Password Changing** > **Configure Dependency Changers** >
 - Click on Create New Dependency Changer
 - Type "PowerShell Script"
 - Select "Windows Autologon" from the previous tutorial
 - Name: Autologon Dependency
 - Check the box for "Create Template"

2.1. Click on the Scripts Tab:
    - Leave the box unchecked for "Use Advanced Scripts"
    - Select the Script from the previous steps
    - Arguments: $[1]$USERNAME $[1]$DOMAIN $[1]$PASSWORD $MACHINE $PASSWORD
    - Save
