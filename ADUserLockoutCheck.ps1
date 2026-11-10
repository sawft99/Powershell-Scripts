#Check for locked out users against list of domain controllers

$DomainControllers = (Get-ADGroupMember 'Domain Controllers').Name
[int]$Loops = 0 # 0 = Infinite
[int]$Delay = 10 # Delay in seconds between each group of servers, 0 = No delay

#------------

Clear-Host

Write-Host "
---------------------
AD User Lockout Check
---------------------

Using: $($DomainControllers -join ',')
"

function LockoutCheck {
    $Lockout = $null
    $Lockout = foreach ($Server in $DomainControllers) {
        #Write-Host "Checking server $Server..."
        $LockSearch = Search-ADAccount -UsersOnly -LockedOut -Server $Server
        $LockSearch
    }
    $Lockout = $Lockout | Select-Object -Unique
    $Lockout = foreach ($User in $Lockout) {
        $Query = Get-ADUser -Identity $User -Properties Name,SAMAccountName,Enabled,LockedOut,Enabled,LastBadPasswordAttempt
        $Query
    }
    $Lockout | Format-Table Name,SAMAccountName,Enabled,LastBadPasswordAttempt,LockedOut #,LockoutTime
}

if ($Loops -eq 0) {
    do {
        $i = 0
        $Lockout = LockoutCheck
        Start-Sleep $Delay
        #Write-Host ''
        $Lockout #| Format-Table CN,LockoutTime,Enabled,LastBadPasswordAttempt
    } until ($i -eq 1)
} else {
    $i = 0
    do {
        $Lockout = LockoutCheck
        Start-Sleep $Delay
        #Write-Host ''
        $Lockout #| Format-Table CN,LockoutTime,Enabled,LastBadPasswordAttempt
        $i = $i + 1
    } until ($i -eq $Loops)
}
