#Simple script that finds disabled computers.

$OutLocation = #Location
$Base = #"OU=Disabled Computers,DC=Domain,DC=TLD"
Get-ADComputer -SearchBase $Base -SearchScope 2 -filter * -Properties Name,LastLogonDate | Sort-Object -Property LastLogonDate -Descending | Export-Csv -Path $OutLocation\Info.csv -NoTypeInformation -NoClobber -Encoding UTF8
