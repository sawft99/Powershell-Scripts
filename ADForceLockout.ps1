#Force a lockut of an AD account with repeated bad credentials

#$TLD = 'com'
$Domain = $env:USERDNSDOMAIN
$User = 'test'
[int]$Loops = 15
$Delay = 5 # In seconds, delay between each attempt

$DomainControllers = (Get-ADGroupMember 'Domain Controllers').Name
$FullUsername = $Domain + '\' + $User
$UPN = $User + '@' + $Domain #+ '.' + $TLD

#------------

[int]$i = 0
$Error.Clear()
Clear-Host

Write-Host "
------------------
Force User Lockout
------------------

Servers: $($DomainControllers -join ',')
User:    $FullUserName ($UPN)"

if ($Loops -le 0) {
    Write-Host ''
    Write-Host -ForegroundColor Red 'Enter a positive value for the number of $Loops'
    exit 1
}

$Credentials = Get-Credential -UserName $FullUsername -Message 'Enter a bad password for the user'

function CheckLock {
    $Lockout = $null
    $Lockout = foreach ($Server in $DomainControllers) {
        Write-Host "Checking server $Server..."
        $Query = Get-ADUser -Filter {UserPrincipalName -eq $UPN} -Server $Server -Properties LockedOut
        if ($null -eq $Query) {
            Write-Host -ForegroundColor Red 'User not found'
            exit 1
        }
        $Query
        if ($Query.LockedOut -eq $true) {
            Write-Host User locked on server $Server
        }
    }
    $Lockout = $Lockout.LockedOut | Where-Object {$_ -eq $true}
    if ($Lockout -gt 0) {
        $Lockout = $true
    } else {
        $Lockout = $false
    }
    $Lockout
}

function Lockout {
    $i = $i + 1
    Write-Host "Lockout attempt $i"
    Start-Sleep $Delay
    $ErrorVar = $null
    Invoke-Command -Credential $Credentials -ScriptBlock {notepad.exe} -ComputerName $env:COMPUTERNAME -ErrorAction SilentlyContinue -ErrorVariable ErrorVar | Out-Null
    if ($null -eq $ErrorVar) {
        Write-Host ''
        Write-Host -ForegroundColor Red 'You supplied the correct credentials
        '
        exit 1
    }
}

do {
    $Lockout = CheckLock
    if ($Lockout -eq $true) {
        Write-Host ''
        Write-Host -ForegroundColor Green 'User locked
        '
        exit 0
    }
    Write-Host ''
    Lockout
    $i = $i + 1
} until ($i -eq ($Loops + 1))

$Lockout = LockoutCheck

if ($Lockout -ne $true) {
    Write-Host ''
    Write-Host -ForegroundColor Red 'Failed to lock user'
}
