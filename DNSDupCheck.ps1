#Find duplicate dns entries

$Domain = 'example.com'
$DNSServer = 'MyDNSServer'

Clear-Host

#All A records, excluding static and some other special ones
$ARecords = Get-DnsServerResourceRecord -ComputerName $DNSServer -ZoneName $Domain -RRType A | Where-Object {($_.Timestamp -ne $null) -and ($_.HostName -ne '@') -and ($_.HostName -notmatch 'DnsZones') -and ($_.Hostname -notmatch $Domain)} | Select-Object -Property HostName,Timestamp,RecordData 

#Create table with Name, timestamp, and IPv4 address
$ARecordsFormatted = $ARecords | Select-Object -Property HostName, Timestamp, @{Name='IPv4Address'; Expression={$_.RecordData.IPv4Address}}

#Group based on IP and only when the same IP is seen more than 2 times
$DuplicateNames = ($ARecordsFormatted | Group-Object -Property IPv4Address) | Where-Object -Property Count -gt 1

#Create table again and sort from least duplicates to most
$Final = $DuplicateNames | Select-Object Count, @{Name='IPv4Address'; Expression={$_.Name}},@{Name='HostNames'; Expression={$_.Group.HostName -join ', '}} | Sort-Object -Property Count

$Final
