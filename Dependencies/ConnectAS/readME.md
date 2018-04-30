# ConnectAS IIS account Dependency Changer

This will push the password to IIS configurations for ConnectAs accounts

| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | Any Supported |
| PowerShell | Windows Management Framework 3+ |

## Prerequisites

- Powershell remoting enabled on these machines
- [ConnectAs Discovery](https://github.com/thycotic/Discovery/tree/master/IIS-ConnectAS-Account "IIS ConnectAS Discovery")

## Configuration

1. Add Autologon.ps1 script to Secret Server:
   - **ADMIN** > **Scripts**

2. Configure Dependency Changer:
   - **ADMIN** > **Remote Password Changing** > **Configure Dependency Changers** >
   - Click on Create New Dependency Changer and select the following:
       - Type: "PowerShell Script"
       - Scan Template: "Connect As" - from the previous tutorial See prerequisites
       - Name: ConnectAs Dependency Changer
       - Description: Connect As on %TARGET%
       - Check the box for "Create Template"
   - Click on the Scripts Tab:
       - Leave the box unchecked for "Use Advanced Scripts"
       - Select the Script from the previous steps
       - Arguments $ComputerName $ItemXPath $Domain $UserName $Password
       - Save
