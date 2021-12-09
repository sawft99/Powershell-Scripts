#Script that finds disabled computers and moves them to an OU.
#DisableDateCutoff and DeleteDateCutoff dates measured in days. Example '$DisableDateCutoff = 90' for 90 days less than current date

$Base = #"OU=Computers,DC=Domain,DC=Local"
$DisabledPCsOU = #"OU=DisabledComputers,DC=Domain,DC=Local"
$DisableDateCutoff = 90
$DeleteDateCutoff = 120
$CurrentDate = Get-Date
$DisableDate = $CurrentDate.AddDays(-$DisableDateCutoff)
$DeleteDate = $CurrentDate.AddDays(-$DeleteDateCutoff)

$Computers = Get-ADComputer -SearchBase $Base -SearchScope 2 -filter *

ForEach ($Computer in $Computers) {
    If ((New-TimeSpan -Start $DisableDate -End $CurrentDate).Days -GT $DisableDateCutoff) {
        Set-ADComputer -Identity $Computer.ObjectGUID -Enabled $false
        Move-ADObject -Identity $Computer.ObjectGUID -TargetPath $DisabledPCsOU 
    }
}

$DisabledComputers = Get-ADComputer -SearchBase $DisabledPCsOU -SearchScope 2 -filter *

ForEach ($DisabledComputer in $DisabledComputers) {
    If ((New-TimeSpan -Start $DeleteDate -End $CurrentDate).Days -GT $DeleteDateCutoff) {
        Remove-ADComputer -Identity $DisabledComputer.ObjectGUID
    }
}
