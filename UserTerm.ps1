#Script for user termination in 365/Azure/Entra/Exchange services
#Relies on MS Graph and Exchange Online powershell modules 

$DisconnectAtEnd = $true #$True or $False. $False for doing batches

#--------

Clear-Host
Write-Output "================
User Termination
================
"

#Check for $DisconnectAtEnd variable value
if (($DisconnectAtEnd -ne $true) -and ($DisconnectAtEnd -ne $false)) {
    Write-Host '$DisconnectAtEnd' needs to be '$True' or '$False'
    exit 1
}

#Prompt for UPN
do {
    $TermUser = Read-Host -Prompt 'Users UPN (Person@example.com)'
} until (
    ($null -ne $TermUser) -and ($TermUser -match '@')
)

#Confirming UPN and user
Write-Host -ForegroundColor Red 'SAFETY SWITCH!'
Read-Host -Prompt "Press ENTER to confirm termination for $TermUser"

#Random password generator
function MakeRandomPassword {
    $TokenSet = @{
        U = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        L = [Char[]]'abcdefghijklmnopqrstuvwxyz'
        N = [Char[]]'0123456789'
        S = [Char[]]'!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~'
    }
    $Upper = Get-Random -Count 8 -InputObject $TokenSet.U
    $Lower = Get-Random -Count 8 -InputObject $TokenSet.L
    $Number = Get-Random -Count 8 -InputObject $TokenSet.N
    $Special = Get-Random -Count 8 -InputObject $TokenSet.S
    $StringSet = $Upper + $Lower + $Number + $Special
    (Get-Random -Count 25 -InputObject $StringSet) -join ''
}

#Connect to MSGraph service with needed permissions
$GraphConnectionCheck = Get-MgContext
if ($null -eq $GraphConnectionCheck) {
    Write-Output 'No MgGraph session found, connecting...'
    Connect-MgGraph -NoWelcome -Scopes @(
    "AuditLog.Read.All",
    "Calendars.ReadWrite",
    "Directory.Read.All",
    "Directory.ReadWrite.All",
    "Directory.AccessAsUser.All",
    "email",
    "Group.Read.All",
    "Organization.Read.All",
    "openid",
    "Policy.Read.All",
    "profile",
    "Reports.Read.All",
    "UserAuthenticationMethod.Read.All",
    "UserAuthenticationMethod.ReadWrite.All",
    "User.Read",
    "User.Read.All",
    "User.ReadWrite.All",
    "User.RevokeSessions.All"
)
    $GraphConnectionCheck = Get-MgContext
    if ($null -eq $GraphConnectionCheck) {
        Write-Output 'Issue connecting to Mg-Graph, exiting...'
        exit 1
    } else {
        Write-Output 'Mg-Graph connected!'
    }
} else {
    Write-Output 'Mg-Graph already connected, skipping...'
}

#Exchange Online connection check
Import-Module ExchangeOnlineManagement
$ExchangeConnectionCheck = Get-ConnectionInformation
if ($null -ne $ExchangeConnectionCheck) {
    Write-Output 'Exchange already connected, skipping...'
} else {
    Write-Output 'No Exchange session found, connecting...'
    Connect-ExchangeOnline -ShowBanner:$false | Out-Null
    $ExchangeConnectionCheck = Get-ConnectionInformation
    if ($null -ne $ExchangeConnectionCheck) {
        Write-Output 'Exchange connected!'
    } else {
        Write-Output 'Exchange failed to connect'
        exit 1
    }
}

#Get user info
Write-Output 'Getting user info...'
$User = Get-MgUser -Search UserPrincipalName:$TermUser -ConsistencyLevel eventual

if ($null -eq $User) {
    Write-Output 'User not found, exiting...'
    exit 1
}

#Reset users password to something random
Write-Output 'Resetting password...'
$NewPassword = MakeRandomPassword
Update-MgUser -UserId $User.Id -PasswordProfile @{
    Password = $NewPassword
    ForceChangePasswordNextSignIn = $false
}

#Reset & Revoke MFA
Write-Output 'Removing and resetting MFA...'
Import-Module Microsoft.Graph.Identity.SignIns
Revoke-MgUserSignInSession -UserId $User.Id | Out-Null
#Can't delete default method so this may error out
Get-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $User.Id | ForEach-Object {
   Remove-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $User.Id -MicrosoftAuthenticatorAuthenticationMethodId $_.Id
}

#Disable user
Write-Output 'Disabling user...'
Update-MgUser -UserId $User.Id -AccountEnabled:$false

#Revoke tokens
Write-Output 'Revoking tokens...'
Revoke-MgUserSignInSession -UserId $User.Id | Out-Null

#Convert to shared mailbox
Write-Output 'Checking on mailbox...'
$MailboxCheck = Get-Mailbox -Identity $TermUser -ErrorAction SilentlyContinue
if ($null -ne $MailboxCheck) {
    Write-Output 'Mailbox found!'
    if ($MailboxCheck.RecipientTypeDetails -ne 'SharedMailbox') {
        Write-Output 'Converting to a shared mailbox...'
        Set-Mailbox -Identity $TermUser -Type Shared
        Write-Output 'Waiting to recheck mailbox...'
        Start-Sleep -Seconds 10
        $MailboxCheck = Get-Mailbox -Identity $TermUser -ErrorAction SilentlyContinue
        if ($MailboxCheck.RecipientTypeDetails -ne 'SharedMailbox') {
            Write-Host -ForegroundColor Red 'Failed to convert mailbox to Shared, stopping...'
            exit 1
        } else {
            Write-Host -ForegroundColor Green 'Mailbox converted to Shared'
        }
    } else {
        Write-Host -ForegroundColor Yellow 'User already set to shared mailbox, skipping...'
    }
} else {
    Write-Host -ForegroundColor Yellow 'User mailbox not found, skipping...'
}

#Remove licenses
Write-Output 'Checking licenses...'
$Licenses = Get-MgUserLicenseDetail -UserId $User.id | Select-Object *
if ($null -ne $Licenses) {
    Write-Output 'Removing licenses...'
    Set-MgUserLicense -UserId $User.Id -RemoveLicenses $Licenses.SkuId -AddLicenses @{} | Out-Null
} else {
    Write-Output 'No licenses, skipping...'
}

#Disable devices
#Write-Output 'Disabling devices...
#Get-MgUserRegisteredDevice -UserId $User.Id -All | ForEach-Object {
#    Update-MgDevice -DeviceId $_.Id -AccountEnabled:$false
#}

if ($null -ne $TermUser) {
    Remove-Variable TermUser
}

if ($DisconnectAtEnd -eq $true) {
    Write-Output 'Disconnecting Mg-Graph and Exchange Online...'
    Disconnect-MgGraph | Out-Null
    Disconnect-ExchangeOnline -Confirm:$false | Out-Null
}

Write-Host -ForegroundColor Green 'Done!'
