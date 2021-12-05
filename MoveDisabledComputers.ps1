#Script that finds disabled computers and moves them to an OU.
#DisableDateCutoff and DeleteDateCutoff dates measured in days

$Base = #"OU=Computers,DC=Domain,DC=Local"
$NewOU = #"OU=DisabledComputers,DC=Domain,DC=Local"
$DisableDateCutoff = 90
$DeleteDateCutoff = 120
$CurrentDate = Get-Date
$90DaysAgo = $CurrentDate.AddDays(-$DisableDateCutoff)
$120DaysAgo = $CurrentDate.AddDays(-$DeleteDateCutoff)

$Computers = Get-ADComputer -SearchBase $Base -SearchScope 2 -filter *

ForEach ($Computer in $Computers) {
    If ($90DaysAgo -GT $Computer.LastLogonDate) {
        Set-ADComputer -Identity $Computer.ObjectGUID -Enabled $false
        Move-ADObject -Identity $Computer.ObjectGUID -TargetPath $NewOU 
    }
}

$DisabledComputers = Get-ADComputer -SearchBase $NewOU -SearchScope 2 -filter *

ForEach ($DisabledComputer in $DisabledComputers) {
    If ($120DaysAgo -GT $DisabledComputer.LastLogonDate) {
        Remove-ADComputer -Identity $DisabledComputer.ObjectGUID
    }
}