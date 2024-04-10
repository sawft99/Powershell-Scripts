#Loop on checking for recent bad password attempts

$ADGroup = 'Domain Users'
$LogOption = $true # or '$false'
$LogLocation = 'C:\Log.txt'

[int]$Loops = 0 # 0 = Infinite
[int]$UserDelay = 0 # # 0 = No delay, measured in seconds, delay between each user query
[int]$SeriesDelay = 60 # 0 = No delay, measured in seconds, delay between each group of users query

#Time since bad password. Example: if $Days = 1 it will look at bad attempts in the past 24 hours
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
$Users = (Get-ADGroupMember -Identity "$ADGroup").SID.Value
Write-Host "
Checking $($Users.Count) users...
"

function BadPassCheck {
        $UsersQuery = foreach ($User in $Users) {
            Start-Sleep $UserDelay
            if ($null -ne $FinalInfo) {
                Remove-Variable FinalInfo
            }
            [datetime]$Time = Get-Date
            [datetime]$TimeDiff = $Time.AddDays(-$Days).AddHours(-$Hours).AddMinutes(-$Minutes).Add(-$Seconds)
            $Info = Get-ADUser $User -Properties LastBadPasswordAttempt
            if ($null -ne $Info.LastBadPasswordAttempt) {
                [datetime]$BadPassTime = $Info.LastBadPasswordAttempt
                $FinalInfo = $Info | Where-Object {$BadPassTime -ge $TimeDiff}
            }
            $FinalInfo
        }
        if (($Loops -gt 1) -or ($Loops -eq 0)) {
            #Uncomment if you want to have a header to break up each section
            [string]$Time = (Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt')
            #Write-Host '-----------------------------------'
            #Write-Host "Series Break: $Time"
            #Write-Host '-----------------------------------'
            if ($LogOption -eq $true) {
                #Uncomment if you want to have a header to break up each section
                [string]$Time = (Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt')
                '-------------------------------------' | Out-File -Append $LogLocation
                "Series Break: $Time"                   | Out-File -Append $LogLocation
                '-------------------------------------' | Out-File -Append $LogLocation
            }
        }
    $UsersQuery
}

if ($Loops -ge 1) {
    [int]$i = 0
    do {
        if ($i -ge 1) {
            Start-Sleep $SeriesDelay
        }
        $Check = BadPassCheck
        if ($LogOption -eq $true) {
            $Check | Format-Table Name,SamAccountName,LastBadPasswordAttempt | Out-File $LogLocation -Append
        }
        $Check | Format-Table Name,SamAccountName,LastBadPasswordAttempt
        $Check = $null
        $i = $i + 1
    } until ($i -eq $Loops)
} elseif ($Loops -eq 0) {
    [int]$i = 0
    do {
        if ($i -ge 1) {
            Start-Sleep $SeriesDelay
        }
        $Check = BadPassCheck
        $Check | Format-Table Name,SamAccountName,LastBadPasswordAttempt
        if ($LogOption -eq $true) {
            $Check | Format-Table Name,SamAccountName,LastBadPasswordAttempt | Out-File $LogLocation -Append
        }
        $Check = $null
        $i = $i + 1
    } until ($i -lt $Loops)
} else {
    Write-Host -ForegroundColor Red 'Bad $Loop value'
}
