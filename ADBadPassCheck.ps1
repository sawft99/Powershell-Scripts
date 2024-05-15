#Loop on checking for recent bad password attempts
#Using both PrimaryGroup and MemberOf properties because if Domain Users is the primary group it won't show under the MemberOf property. Doing both with an 'or' statements allows it to pull a group either way

$ADGroupNameFilter = 'Domain Users'
$ADGroupScopeFilter = 'CN=Domain Users,CN=Users,DC=domain,DC=com'
$ADOUScopeFilter = 'OU=JDHCOUsers,DC=DOMAIN,DC=COM'
$DomainControllers = (Get-ADGroupMember 'Domain Controllers').Name # @('DC01','DC02','DC03')
$LogOption = $true # or '$false'
[System.IO.FileInfo]$LogLocation = 'C:\Log.txt'

[int]$Loops = 0 # 0 = Infinite
[int]$UserDelay = 0 # 0 = No delay, measured in seconds, delay between each user query
[int]$ServerDelay = 5 # 0 = No delay, measured in seconds, delay between each server query 
[int]$SeriesDelay = 5 # 0 = No delay, measured in seconds, delay between each group of users query

#Time since bad password. Example: if $Days = 1 it will look at bad attempts in the past 24 hours
#Time and the difference is calculated with each uer query
#As an example, you specify 1 hour as the time difference, it is 9:00 AM, and the user last entered a bad password at 8:05 AM
#If the scripts runs for 10 minutes until it gets to that particular user on the server they entered a bad password on, it will not be recorded
#The more users and DC's you have the more buffer room you should add   
[int]$Days = 0
[int]$Hours = 0
[int]$Minutes = 10
[int]$Seconds = 0

#--------------

Clear-Host

Write-Host '
=====================
AD Bad Password Check
=====================
'
Write-Host "Looking for users with bad password attempts in the past $Days day(s),$Hours hour(s),$Minutes minute(s),and $Seconds second(s)"
$Users = Get-ADUser -SearchBase $ADOUScopeFilter -Filter {(PrimaryGroup -eq $ADGroupScopeFilter) -or (memberof -eq $ADGroupNameFilter)}
Write-Host "
Checking $($Users.Count) users...
"
if ($Users.Count -lt 1) {
    Write-Host -ForegroundColor Red 'No users, exiting...'
    exit 1
}

function BadPassCheck {
    $Results = foreach ($Server in $DomainControllers) {
        Start-Sleep $ServerDelay
        $UsersQuery = foreach ($User in $Users) {
            Start-Sleep $UserDelay
            if ($null -ne $FinalInfo) {
                Remove-Variable FinalInfo
            }
            [datetime]$Time = Get-Date
            [datetime]$TimeDiff = $Time.AddDays(-$Days).AddHours(-$Hours).AddMinutes(-$Minutes).Add(-$Seconds)
            $Info = Get-ADUser $User -Server $Server -Properties LastBadPasswordAttempt,LockedOut,BadPwdCount
            if ($null -ne $Info.LastBadPasswordAttempt) {
                [datetime]$BadPassTime = $Info.LastBadPasswordAttempt
                $FinalInfo = $Info | Where-Object {$BadPassTime -ge $TimeDiff}
                $FinalInfo | Add-Member -MemberType NoteProperty -Name 'Server' -Value $Server -Force
            }
            $FinalInfo
        }
        $UsersQuery
    }
    if (($Loops -gt 1) -or ($Loops -eq 0)) {
        if ($null -ne $Results) {
            [string]$Time = (Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt')
            Write-Host '-------------------------------------'
            Write-Host "Series Break: $Time"
            Write-Host '-------------------------------------'
        }
        if ($LogOption -eq $true) {
            if ($null -ne $Results) {
                [string]$Day = (Get-Date).ToString('MM-dd-yyyy')
                $LogLocation = ($LogLocation.FullName -split $LogLocation.Extension)[0] + '-' + $Day + $LogLocation.Extension
                [string]$Time = (Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt')
                '-------------------------------------' | Out-File -Append $LogLocation
                "Series Break: $Time"                   | Out-File -Append $LogLocation
                '-------------------------------------' | Out-File -Append $LogLocation
            }
        }
    }
    $Results | Sort-Object -Property Name
}

if ($Loops -ge 1) {
    [int]$i = 0
    do {
        if ($i -ge 1) {
            Start-Sleep $SeriesDelay
        }
        $Check = BadPassCheck
        if (($LogOption -eq $true) -and ($null -ne $Check)) {
            [string]$Day = (Get-Date).ToString('MM-dd-yyyy')
            $LogLocation = ($LogLocation.FullName -split $LogLocation.Extension)[0] + '-' + $Day + $LogLocation.Extension
            $Check | Format-Table Name,SamAccountName,LastBadPasswordAttempt,BadPwdCount,LockedOut,Server -AutoSize | Out-File $LogLocation -Append
        }
        Write-Output $Check | Format-Table Name,SamAccountName,LastBadPasswordAttempt,BadPwdCount,LockedOut,Server -AutoSize
        $i = $i + 1
    } until ($i -eq $Loops)
} elseif ($Loops -eq 0) {
    [int]$i = 0
    do {
        if ($i -ge 1) {
            Start-Sleep $SeriesDelay
        }
        $Check = BadPassCheck
        $Check | Format-Table Name,SamAccountName,LastBadPasswordAttempt,BadPwdCount,LockedOut,Server -AutoSize
        if (($LogOption -eq $true) -and ($null -ne $Check)) {
            [string]$Day = (Get-Date).ToString('MM-dd-yyyy')
            $LogLocation = ($LogLocation.FullName -split $LogLocation.Extension)[0] + '-' + $Day + $LogLocation.Extension
            Write-Output $Check | Format-Table Name,SamAccountName,LastBadPasswordAttempt,BadPwdCount,LockedOut,Server -AutoSize | Out-File $LogLocation -Append
        }
        $i = $i + 1
    } until ($i -lt $Loops)
} else {
    Write-Host -ForegroundColor Red 'Bad $Loop value'
}
