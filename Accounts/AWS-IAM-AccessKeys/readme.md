# AWS Access Key Rotation

These custom script will rotate AWS access keys and verify the rotation was successful. The rotation follows AWS best practices

## Configuration

### Create the Template

* Add the Scripts to Secret Server. Admin > Scripts > Create New
* Create a Template for Access Keys > Admin > Templates > Create New and name it
  * Field Name= AccessKey, Type=Text, Required
  * Field Name= SecretKey, Type=Password, Required
  * Field Name= Username, Type=Text, Required
  * Field Name= SecretId, Type=Password, Required
  * Field Name= Trigger, Type=Text, Required
* Save or click back to finish Creating the template

### Create the Password Changer

* Navigate to Admin > Remote Password Changing > Configure Password Changers > New
* Call it something relevant, **PowerShell Script** from the drop down menu, Save
  * Verify Password Changed Commands:
    * choose the Heartbeat script from the drop down
    * Script Args: $AccessKey $SecretKey $Username
    * Save
  * Password Change Commands:
    * choose the Access key rotation script from the drop down
    * Script Args: $AccessKey $SecretKey $[1]$Username $[1]$Password $Secretid
      * $[1]$Username $[1]$Password are optional. Read below for explanation

## Usage

TODO: Write usage instructions

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D