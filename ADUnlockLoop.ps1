#Loop unlocking a specific user account

$User = 'user@example.com' # UPN formating
[int]$Delay = 60 #Delay in seconds, time between each check of account status
[int]$Loops = 0 # 0 = infinite

#----------

$User = Get-ADUser -Filter {UserPrincipalName -like $User} -Properties *

Clear-Host

Write-Host "
-----------------
Unlock User Loop
-----------------

User: $($User.SamAccountName)
"

function CheckLockStatus {
    $Time = Get-Date
    $Status = Get-ADUser $User -Properties LockedOut
    $Status
}

function UnlockAccount {
    $Time  = Get-Date
    Unlock-ADAccount $User
}

if ($Loops -eq 0) {
    do {
       if ($null -ne $Status) {
            Remove-Variable Status
        }
        $i = 0
        $Status = CheckLockStatus
        if ($Status -eq 'True') {
            $Time = Get-Date -Format 'MM/dd/yyyy hh:mm tt'
            Write-Host "Account was locked at $($Time)"
            UnlockAccount
        }
        Start-Sleep $Delay
    } until ($i -eq 1)
} else {
    $i = 0
    do {
        if ($null -ne $Status) {
            Remove-Variable Status
        }
        $Status = CheckLockStatus
        if ($Status -eq 'True') {
            $Time = Get-Date -Format 'MM/dd/yyyy hh:mm tt'
            Write-Host "Account was locked at $($Time)"
            UnlockAccount
        }
        $i = $i + 1
        Write-Host $i
        Start-Sleep $Delay
    } until ($i -eq $Loops)
}
