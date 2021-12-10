#Script that finds disabled computers and moves them to an OU.
#DisableDateCutoff and DeleteDateCutoff dates measured in days. Example '$DisableDateCutoff = 90' for 90 days less than current date

#Working OUs and date cutoff variables
$Base = #"OU=Computers,DC=Domain,DC=Local"
$DisabledPCsOU = #"OU=DisabledComputers,DC=Domain,DC=Local"
$DisableDateCutoff = 90
$DeleteDateCutoff = 120

#Create dates for disable and delete thresholds
$CurrentDate = Get-Date
$DisableDate = $CurrentDate.AddDays(-$DisableDateCutoff)
$DeleteDate = $CurrentDate.AddDays(-$DeleteDateCutoff)

#Get all computers in OU and subtree.
$Computers = Get-ADComputer -SearchBase $Base -SearchScope 2 -filter *

#If computer has not been logged into for X days move it
ForEach ($Computer in $Computers) {
    If ((New-TimeSpan -Start $DisableDate -End $CurrentDate).Days -GT $DisableDateCutoff) {
        Set-ADComputer -Identity $Computer.ObjectGUID -Enabled $false
        Move-ADObject -Identity $Computer.ObjectGUID -TargetPath $DisabledPCsOU 
    }
}

#Find disabled computers in the $DisabledPCsOU
$DisabledComputers = Get-ADComputer -SearchBase $DisabledPCsOU -SearchScope 2 -filter *

#Delete PCs in OU that have not been logged into for X days
ForEach ($DisabledComputer in $DisabledComputers) {
    If ((New-TimeSpan -Start $DeleteDate -End $CurrentDate).Days -GT $DeleteDateCutoff) {
        Remove-ADComputer -Identity $DisabledComputer.ObjectGUID
    }
}
