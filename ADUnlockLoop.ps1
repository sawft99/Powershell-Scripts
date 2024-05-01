#Loop on unlocking a specific user account

$User = 'user@example.com' # UPN formatting
[int]$SeriesDelay = 5 #Delay in seconds, time between each series check of account status
[int]$ServerDelay = 0 #Delay in seconds, time between each servers check of account status
[int]$Loops = 0 # 0 = infinite
$LogOption = $true
$LogFolder = 'C:\Logs'
#Will create a log called 'Unlock-UserNameHere.txt'
$LogLocation = $LogFolder + '\Unlock-' + ($User -split '@')[0] + '.txt'

$DomainControllers = (Get-ADGroupMember 'Domain Controllers').Name

#----------

$User = Get-ADUser -Filter {UserPrincipalName -like $User}
if ($null -eq $User) {
    Write-Host -ForegroundColor Red 'User does not exist'
    exit 1
}

Clear-Host

Write-Host "
=================
Unlock User Loop
=================

User: $($User.SamAccountName)
"

function CheckLockStatus {
    $Status = foreach ($Server in $DomainControllers) {
        Start-Sleep $ServerDelay
        #Write-Host "Checking server $Server"
        [string]$Time = Get-Date -Format 'MM/dd/yyyy hh:mm tt'
        $Check = (Get-ADUser $User -Properties LockedOut -Server $Server).LockedOut
        if ($Check -eq $true) {
            #$Check | Add-Member -MemberType NoteProperty -Name Server -Value $Server
            Write-Host "User locked on $Server at $Time"
            if ($LogOption -eq $true) {
                "User locked on $Server at $Time" | Out-File -Append $LogLocaiton
            }
        }
        $WholeObject = [PSCustomObject]@{
            Server = $Server
            Locked = $Check
        }
        $WholeObject
    }
    $Status
}

function CheckLockStatusIndividual {
    $Server = $args[0]
    $Status = (Get-ADUser $User -Properties LockedOut -Server $Server).LockedOut
    $Status
}

function UnlockAccount {
    Write-Host 'Unlocking account...'
    $LockedServers = ($Status | Where-Object -Property Locked -eq $true).Server
    foreach ($Server in $LockedServers) {
        [string]$Time = Get-Date -Format 'MM/dd/yyyy hh:mm tt'
        Unlock-ADAccount $User -Server $Server
        $Status = CheckLockStatusIndividual $Server
        if ($Status -eq $false) {
            Write-Host "Unlocked account on server $Server at $Time"
            if ($LogOption -eq $true) {
                "Unlocked account on server $Server at $Time" | Out-File -Append $LogLocaiton
            }
        } else {
            Write-Host "Failed to unlock account on server $Server at $Time"
            if ($LogOption -eq $true) {
                "Failed to unlock account on server $Server at $Time" | Out-File -Append $LogLocaiton
            }
        }
    }
}

if ($Loops -eq 0) {
    do {
       if ($null -ne $Status) {
            Remove-Variable Status
       }
        $i = 0
        $Status = CheckLockStatus
        if (($Status.Locked -eq $true.count -gt 0)) {
            $Time = Get-Date -Format 'MM/dd/yyyy hh:mm tt'
            #Write-Host "Account was locked at $($Time)"
            UnlockAccount
        }
        Start-Sleep $SeriesDelay
    } until ($i -eq 1)
} else {
    $i = 0
    do {
        if ($null -ne $Status) {
            Remove-Variable Status
        }
        $Status = CheckLockStatus
        if (($Status.Locked -eq $true.count -gt 0)) {
            $Time = Get-Date -Format 'MM/dd/yyyy hh:mm tt'
            #Write-Host "Account was locked at $($Time)"
            UnlockAccount
        }
        $i = $i + 1
        Start-Sleep $SeriesDelay
    } until ($i -eq $Loops)
}
