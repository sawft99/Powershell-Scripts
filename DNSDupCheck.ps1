#Find duplicate DNS entries

$Domain = 'example.com'
$DNSServer = 'MyDNSServer'
$IncludeStaticRecords = $false

Clear-Host

Write-Host '
=====================
DNS Duplicate Records
====================='

#All A records, excluding some special ones
if ($IncludeStaticRecords -eq $false) {
    $ARecords = Get-DnsServerResourceRecord -ComputerName $DNSServer -ZoneName $Domain -RRType A | Where-Object {($_.Timestamp -ne $null) -and ($_.HostName -ne '@') -and ($_.HostName -notmatch 'DnsZones') -and ($_.Hostname -notmatch $Domain)} | Select-Object -Property HostName,Timestamp,RecordData
} elseif ($IncludeStaticRecords -eq $true) {
    $ARecords = Get-DnsServerResourceRecord -ComputerName $DNSServer -ZoneName $Domain -RRType A | Where-Object {($_.HostName -ne '@') -and ($_.HostName -notmatch 'DnsZones') -and ($_.Hostname -notmatch $Domain)} | Select-Object -Property HostName,Timestamp,RecordData
} else {
    Write-Host ''
    Write-Host -ForegroundColor Red '$IncludeStaticRecords needs to be $true or $false'
    exit 2
}

#Create table with Name, timestamp, and IPv4 address
$ARecordsFormatted = $ARecords | Select-Object -Property HostName, Timestamp, @{Name='IPv4Address'; Expression={$_.RecordData.IPv4Address}}

#Group based on IP and only when the same IP is seen more than 1 time
$DuplicateNames = ($ARecordsFormatted | Group-Object -Property IPv4Address) | Where-Object -Property Count -gt 1

#Create table again and sort from least duplicates to most
$Final = $DuplicateNames | Select-Object Count, @{Name='IPv4Address'; Expression={$_.Name}},@{Name='HostNames'; Expression={$_.Group.HostName -join ', '}} | Sort-Object -Property Count

if ($null -ne $Final) {
    $Final
} else {
    Write-Host ''
    Write-Host -ForegroundColor Green 'No duplicate records
    '
}
