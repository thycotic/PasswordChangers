# AWS Access Key Rotation

## Description

These custom script will rotate AWS access keys and verify the rotation was successful. The rotation follows AWS best practices.
In order for the rotation to work, we will need AWS PowerShell SDK installed on Secret Server or the Distributed Engines. Secret Server doesn't capture results back from scripts, and since the script is generating the keys on Amazon and not in Secret Server, we need to send the new keys back to Secret Server. We do that by making an API call once we generate the new keys, and put them back in the Secret.

| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | Any Supported |
| PowerShell | Windows Management Framework 3+ |

## Prerequisites

* AWS PowerShell SDK installed on the Secret Server or Engine Machine
* Secret Server configured to execute PowerShell scripts
* Amazon account with IAM access keys

## Configuration

### Create the Template

* Add the Scripts to Secret Server. Admin > Scripts > Create New
* Create a Template for Access Keys > Admin > Templates > Create New and name it
  * Field Name= **AccessKey**, Type=Text, Required
  * Field Name= **SecretKey**, Type=Password, Required
  * Field Name= **Username**, Type=Text, Required
  * Field Name= **SecretId**, Type=Text, Not Required
  * Field Name= **Trigger**, Type=Text, Not Required
* Save or click back to finish Creating the template

### Create the Password Changer**

* Navigate to Admin > Remote Password Changing > Configure Password Changers > New
* Call it something relevant, **PowerShell Script** from the drop down menu, Save
  * Verify Password Changed Commands:
    * choose the Heartbeat script from the drop down
    * Script Args: $AccessKey $SecretKey $Username
    * Save
  * Password Change Commands:
    * choose the Access key rotation script from the drop down
    * Script Args: **$AccessKey $SecretKey $[1]$Username $[1]$Password $Secretid**
      * $[1]$Username $[1]$Password are optional. Read below for explanation

### Associate Changer with the Template

* Navigate back to Secret Templates and Select the Access Key Template > Edit
* Scroll down, click on configure password changing
* Check the box **Enable Remote Password Changing** and **Enable Heartbeat**
* From the drop down menu choose the password changer we created in the earlier step
* Map the fields to the password changer:
  * **Domain = Access Key**
  * **Password = Trigger**
  * **Username = Username**
* Save

## Usage

* Create a new Secret and choose the access key template we created earlier in the process
* Fill in the fields with the Access Key, Secret Key, IAM Username(good for identifying the keys), SecretId (put any number value), 