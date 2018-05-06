# AWS Access Key Rotation

## Description

These custom script will rotate AWS access keys and verify the rotation was successful. The rotation follows AWS best practices.
In order for the rotation to work, we will need AWS PowerShell SDK installed on Secret Server or the Distributed Engines. Secret Server doesn't capture results back from scripts, and since the script is generating the keys on Amazon and not in Secret Server, we need to send the new keys back to Secret Server. We do that by making an API call once we generate the new keys, and put them back in the Secret. The account used to make the call can be either a domain account (recommended since we can use IWA), or local Secret Server account.

| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | Any Supported |
| PowerShell | Windows Management Framework 3+ |

## Prerequisites

* AWS PowerShell SDK installed on the Secret Server or Engine Machine
* Secret Server configured to execute PowerShell scripts
* Amazon account with IAM access keys
* The PowerShell account running the Script needs to be a Secret Server user with edit permissions on the Access Key Secret
* Optional: You can use a local account/API account for the API call back to Secret Server to update the keys

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

### Create the Password Changer

* Navigate to Admin > Remote Password Changing > Configure Password Changers > New
* Call it something relevant, **PowerShell Script** from the drop down menu, Save
  * Verify Password Changed Commands:
    * choose the Heartbeat script from the drop down
    * Script Args: **$AccessKey $SecretKey $Username**
    * Save
  * Password Change Commands:
    * choose the Access key rotation script from the drop down
    * Script Args: **$AccessKey $SecretKey $[1]$Username $[1]$Password $Secretid**
      * ***Note***: $[1]$Username $[1]$Password are optional for calling Secret Server's API and used only if you chose the Alternative Method. Read below for explanation

### Associate Changer with the Template

* Navigate back to Secret Templates and Select the Access Key Template > Edit
* Scroll down, click on configure password changing
* Check the box **Enable Remote Password Changing** and **Enable Heartbeat**
* From the drop down menu choose the password changer we created in the earlier step
* Map the fields to the password changer:
  * **Domain** = **Access Key**
  * **Password** = **Trigger**
  * **Username** = **Username**
* Save

## Usage

* Create a new Secret and choose the Access Key Template we created earlier in the process
* Fill in the fields with:
  * **Access Key** = **Your Access Key**
  * **Secret Key** = **Your Secret Key**
  * **IAM Username** = **the IAM user for these keys**
  * **SecretId** = **The SecretId** (Leave blank on creation. Enter secretId number after you save)
  * **Trigger** = **leave empty**
  * Save
* Navigate to Remote Password Changing tab on the Secret
* Click Edit > **Run PowerShell Using Privileged Account** > Click **No Selected Secret** to choose the Secret which will run PowerShell
* Before Saving, Choose one of the methods below for calling back Secret Server's API:
  * Recommended: Enable Integrated Windows Authentication on Secret Server's web services in IIS in order to use the same PowerShell account for the api call
    * On IIS expand the Secret Server website or application
    * Find the directory winauthwebservices and enable Integrated Windows Authentication (IWA) on it
    * If you need instructions enabling IWA for Secret Server then please check <https://force.thycotic.com>
    * That's all you need, you can Save
  * Alternative: If you can't enable IWA then you need to create a Secret for a Secret Server user account
    * Create a Password, or Web Password based Secret and fill in the blanks
    * On our Access Key right below ***The following Secrets are available to be used in Custom Password Changing Commands and Scripts.***
    * Click on **No Selected Secret**  and choose the API Secret we just created
    * Save
* Whichever method you choose, in both cases the user accounts will need to have Edit permissions on the Access Key Secret