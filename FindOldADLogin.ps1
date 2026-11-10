#Find accounts that haven't logged in for x amount of time

[int]$Days = 186

#---------

Clear-Host

Write-Host '===============
Find Old Logins
===============
'

if ($Days -notin 1..9999999) {
    Write-Host -ForegroundColor Red '$Days needs to be a valid number
    '
    exit 1
}

$Users = Get-ADUser -Filter * -Properties *
$Time = Get-Date

$UserFinal = foreach ($User in $Users) {
    $WholeObject = [PSCustomObject]@{
        User = $User.SamAccountName
        FirstName = $User.GivenName
        LastName = $User.Surname
        DisplayName = $User.DisplayName
        CN = $User.CN
        SID = $User.SID
        Enabled = $User.Enabled
        LastLogon = $User.LastLogonDate
        DaysSince = if ($null -ne $User.LastLogonDate) {[int](($Time - $User.LastLogonDate).TotalDays -split '\.')[0]} else {$null}
        Over = if ($null -ne $User.LastLogonDate) {[int](($Time - $User.LastLogonDate).TotalDays -split '\.')[0] -ge $Days} else {$null}
    }
    $WholeObject
}

$UserTableSimplified = $UserFinal | Where-Object {($_.Enabled -eq $true) -and ($_.Over -eq $true)} | Sort-Object -Property User
$UserTableSimplified | Format-Table
