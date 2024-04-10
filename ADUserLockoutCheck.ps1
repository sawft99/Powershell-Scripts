#Check for locked out users again list of domain controllers

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

Remove-Variable Lockout
$Error.Clear()

function LockoutCheck {
    if ($null -ne $Lockout) {
        Remove-Variable Lockout
    }
    $Lockout = foreach ($Server in $DomainControllers) {
        #Write-Host "Checking server $Server..."
        Search-ADAccount -UsersOnly -LockedOut -Server $Server
    }
    if ($null -ne $Lockout) {
        $Time = Get-Date -Format 'MM/dd/yyyy hh:mm tt'
        $Lockout | Add-Member -MemberType NoteProperty -Name 'LockoutTime' -Value $Time
    }
    $Lockout | Format-Table CN,LockoutTime,Enabled,LastBadPasswordAttempt,LockoutTime
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
