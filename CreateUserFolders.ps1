#Create a user folder for each user. Based off AD username.
#Usefull for auto creating folders for user folder redirection.

$UserFolders = "\\Server.domain.local\Users"
$DNBase = "OU=UsersOU,DC=Domain,DC=local"

$Users = Get-ADUser -SearchBase "$DNBase" -Filter *
$UserNames = $Users.SamAccountName

ForEach ($User in $UserNames) {
    IF (!(Test-Path ("$UserFolders" + "\" + "$User"))) {
        New-Item -Path "$UserFolders\$User" -ItemType Directory
    }
}