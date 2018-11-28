# AWS Access Key Rotation

## Description

These custom script will rotate AWS access keys and verify the rotation was successful. The rotation follows AWS best practices.
In order for the rotation to work, we will need AWS PowerShell SDK installed on Secret Server or the Distributed Engines. Secret Server doesn't capture results back from scripts, and since the script is generating the keys on Amazon and not in Secret Server, we need to send the new keys back to Secret Server. We do that by making an API call once we generate the new keys, and put them back in the Secret. The account used to make the call can be either a domain account (recommended since we can use IWA), or local Secret Server account.

| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | Any Supported |
| PowerShell | Windows Management Framework 5+ |

## Prerequisites
* AWS Tools for PowerShell installed on the Secret Server or Engine Machine
  * https://aws.amazon.com/powershell/
* Secret Server configured to execute PowerShell scripts
* AWS User with IAM Access Keys
  * Applied Policy 
* The PowerShell account running the Script needs to be a Secret Server user with edit permissions on the Access Key Secret
* By Default: Windows Authentication will be used to call back to Secret Server and update the keys.
  * Optional: You may also use a local account account for the call back.

## Configuration
* Add each script to Secret Server. Admin > Scripts > Create New
* Name each script and paste the powershell into the editor
* Your SS URL will need to be input into the bottom line of the script that calls the function. Example: -URL "https://SSURL/SecretServer"
* Optional: If you're using a local account you'll need to comment out the Windows Auth API call at the bottom of the script and uncomment (remove #) from the last line
* Click OK to save your changes.

### Create the Password Changer
* Navigate to Admin > Remote Password Changing > Configure Password Changers > New
* Name the new changer: **AWS IAM AK (PowerShell)**, then choose **PowerShell Script** from the drop down menu, Save
  * Verify Password Changed Commands:
    * choose the Heartbeat script from the drop down
    * Script Args: **$AccessKey $SecretKey $Username $SecretID**
  * Password Change Commands:
    * choose the Access key rotation script from the drop down
    * Script Args: **$AccessKey $SecretKey $Username $SecretID**
    * Save
    * ***Note***: If you are not using IWA for API access you will need to use the following for both Verify Password Changed Commands, and Password Change Commands: **$AccessKey $SecretKey $Username $SecretID $[1]$Username $[1]$Password**  

### Create the Template
* ***Note***: It's important to keep the exact field names below.
* Create a Template for Access Key Rotation: Admin > Templates > Create New and name it
  * Field Name= **AccessKey**, Type=Text, Required
  * Field Name= **SecretKey**, Type=Password, Required
  * Field Name= **Username**, Type=Text, Required
  * Field Name= **SecretId**, Type=Text, Not Required
  * Field Name= **Trigger**, Type=Text, Not Required
* ***Note***: Ensure that you click the + icon at the end of the Trigger row to save that field value

### Associate Changer with the Template
* Scroll down, click on configure password changing
* Check the box **Enable Remote Password Changing** and **Enable Heartbeat**
* From the drop down menu **Password Type to use** choose the password changer we created in the earlier step
* Map the fields to the password changer:
  * **Domain** = **Access Key**
  * **Password** = **Trigger**
  * **Username** = **Username**
  * **Default Privileged Account** = **No Selected Secret**
* Save

## Usage
* Create a new Secret and choose the Access Key Template we created earlier in the process
* Fill in the fields with:
  * **Access Key** = **Your Access Key**
  * **Secret Key** = **Your Secret Key**
  * **IAM Username** = **the IAM user for these keys**
  * **SecretId** = **The SecretId**
    * ***Note***: Leave blank on creation. Get Secret ID from end of URL after Saving. Edit Secret and Update SecretId Field with Value.
  * **Trigger** = **leave empty**
  * Save
* Navigate to Remote Password Changing tab on the Secret
* Click Edit > **Run PowerShell Using Privileged Account** > Click **No Selected Secret** to choose the Secret which will run PowerShell
* Before Saving, Choose one of the methods below for calling back Secret Server's API:
  * Recommended: Enable Integrated Windows Authentication on Secret Server's web services in IIS in order to use the same PowerShell account for the api call
    * On IIS expand the Secret Server website or application
    * Find the directory winauthwebservices and enable Integrated Windows Authentication (IWA) on it
    * If you need instructions enabling IWA for Secret Server then please check <https://thycotic.force.com/support/s/article/Using-Web-Services-with-Windows-Authentication-PowerShell>
    * You will need to conduct an IISReset after enabling Windows Authentication
  * Alternative: If you can't enable IWA then you need to create a Secret for a Secret Server user account
    * Create a Password, or Web Password based Secret and fill in the blanks Username and Password of a Local Secret Server User. This account will need edit access to the AWS Access Key Secret.
    * On our Access Key right below ***The following Secrets are available to be used in Custom Password Changing Commands and Scripts.***
    * Click on **No Selected Secret**  and choose the API Secret we just created
    * Save
    * Navigate to Admin > Scripts

* The user accounts used for API access will need to have Edit permissions on the Access Key Secret
* The user account used for API access will also need at least View permissions on the secret created for its own account.
