#Script that:
#1. Finds computers not logged into for X days and disables them.
#2. Moves those disabled computers to a new OU.
#3. Checks the disabled OU for disabled computers not logged into for X days and deletes them.

#DisableDateCutoff and DeleteDateCutoff dates measured in days. Example '$DisableDateCutoff = 90' for 90 days less than current date

#Working OUs and date variables
#$Base = "OU=Computers,DC=Domain,DC=Local"
#$DisabledPCsOU = "OU=DisabledComputers,DC=Domain,DC=Local"
$DisableDateCutoff = 90
$DeleteDateCutoff = 120
$CurrentDate = Get-Date

#Get all computers in OU and subtree.
$Computers = Get-ADComputer -SearchBase $Base -SearchScope 2 -Filter * -Properties *

#If computer has not been logged into for X days move it
ForEach ($Computer in $Computers) {
    If ((New-TimeSpan -Start ($Computer.LastLogonDate) -End $CurrentDate).Days -GT $DisableDateCutoff) {
        Set-ADComputer -Identity $Computer.ObjectGUID -Enabled $false
        Move-ADObject -Identity $Computer.ObjectGUID -TargetPath $DisabledPCsOU
        Write-Host $Computer.Name disabled and moved to new OU
    }
}

#Find disabled computers in the $DisabledPCsOU
$DisabledComputers = Get-ADComputer -SearchBase $DisabledPCsOU -SearchScope 2 -Filter * -Properties *

#Delete PCs in OU that have not been logged into for X days
ForEach ($DisabledComputer in $DisabledComputers) {
    If ((New-TimeSpan -Start ($DisabledComputer.LastLogonDate) -End $CurrentDate).Days -GT $DeleteDateCutoff) {
        Remove-ADComputer -Identity $DisabledComputer.ObjectGUID
        Write-Host $Computer.Name deleted
    }
}
