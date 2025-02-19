#Loop on unlocking a specific user account

$Users = ('User1','User2','User3') # SamAccountName
[int]$SeriesDelay = 5 #Delay in seconds, time between each series check of account status
[int]$ServerDelay = 0 #Delay in seconds, time between each servers check of account status
[int]$Loops = 0 #0 = infinite
$LogOption = $true
$LogFolder = "$env:USERPROFILE\Logs\Unlocks"

$DomainControllers = (Get-ADGroupMember 'Domain Controllers').Name

#----------

Clear-Host

Write-Host "
=================
Unlock User Loop
=================
"

if (!(Test-Path $LogFolder)) {
    Write-Host -ForegroundColor Red '$LogLocation does not exist'
    exit 1
}

foreach ($User in $Users) {
    $UserTest = Get-ADUser -Filter {SamAccountName -eq $User} -Properties PasswordLastSet
    if ($null -eq $UserTest) {
        Write-Host -ForegroundColor Red "User ($User) does not exist
        "
        exit 1
    } else {
        Write-Host "$($UserTest.SamAccountName) last password change $($UserTest.PasswordLastSet)"
    }
}
Write-Host ''
    
function CheckLockStatus {
    #Write-Host Checking $User
    $Status = foreach ($Server in $DomainControllers) {
        Start-Sleep $ServerDelay
        #Write-Host "Checking server $Server"
        [string]$Time = Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt'
        $Check = (Get-ADUser $User -Properties LockedOut -Server $Server).LockedOut
        if ($Check -eq $true) {
            #$Check | Add-Member -MemberType NoteProperty -Name Server -Value $Server
            Write-Host "$User locked on $Server at $Time"
            if ($LogOption -eq $true) {
                "$User locked on $Server at $Time" | Out-File -Append $LogLocation
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
    Write-Host "Unlocking $User..."
    $LockedServers = ($Status | Where-Object -Property Locked -eq $true).Server
    foreach ($Server in $LockedServers) {
        [string]$Time = Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt'
        Unlock-ADAccount $User -Server $Server
        $Status = CheckLockStatusIndividual $Server
        if ($Status -eq $false) {
            Write-Host "$User unlocked on $Server at $Time"
            if ($LogOption -eq $true) {
                "$User unlocked on $Server at $Time" | Out-File -Append $LogLocation
            }
        } else {
            Write-Host "$User failed to unlock on $Server at $Time"
            if ($LogOption -eq $true) {
                "$User failed to unlock on $Server at $Time" | Out-File -Append $LogLocaiton
            }
        }
    }
}

if ($Loops -eq 0) {
    do {
        foreach ($User in $Users) {
            $LogLocation = $LogFolder + '\Unlock-' + ($User -split '@')[0] + '.txt'
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
        }
    } until ($i -eq 1)
} else {
    $i = 0
    do {
        foreach ($User in $Users) {
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
        }
    } until ($i -eq $Loops)
}
