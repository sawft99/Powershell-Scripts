#Lookup every WhoIs server and some info
[System.IO.DirectoryInfo]$OutputFolder = 'C:\Output'
$DateFormat = 'yyyy-MM-dd'

#------------

Clear-Host

#Test for parent path
$FolderTest = Test-Path $OutputFolder
if ($FolderTest -eq $false) {
    Write-Host -ForegroundColor Red "
Folder does not exist
"
exit 1
}

#Premade variables
$TLDSource = "https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
$WHOISSource = 'https://www.iana.org/whois?q='
$WhoisInfoSource = 'https://who-dat.as93.net/'
$AllTLD = (Invoke-WebRequest -UseBasicParsing -Uri $TLDSource).content -split "\n"
#$DNSTypes = @('A_AAAA','NS','CNAME','SOA','MX','TXT','DS','RRSIG','NSEC','DNSKEY')
#Text document has a header so index starts at 1 and there are extra spaces at the end thus the '- 2'
$AllTLD = $AllTLD[1..($AllTLD.Count - 2)]

function GetWhoisServers {
    $PatternDomain = '^[^\s]+\.[^\s]+'
    $PatternIpv4 = '\b(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
    $PatternIpv6 = '\b(?:(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}:(?:[0-9a-fA-F]{1,4}:){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}:(?:[0-9a-fA-F]{1,4}:){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}:(?:[0-9a-fA-F]{1,4}:){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}:(?:[0-9a-fA-F]{1,4}:){1,5}|[0-9a-fA-F]{1,4}:((?:[0-9a-fA-F]{1,4}:){1,6}|:)|:((?:[0-9a-fA-F]{1,4}:){1,7}|:)|fe80:(?:[0-9a-fA-F]{0,4}:){0,4}%[0-9a-zA-Z]{1,}|::(?:[0-9a-fA-F]{1,4}:){0,5}[0-9a-fA-F]{1,4}|::(?:[0-9a-fA-F]{1,4}:){1,6}|(?:[0-9a-fA-F]{1,4}:){1,7}:|:(?:[0-9a-fA-F]{1,4}:){1,7})\b'
    $WhoisLookup = foreach ($TLD in $AllTLD) {
        Write-Host "Looking up $TLD..."
        $Query = (Invoke-WebRequest -UseBasicParsing -Uri ($WHOISSource + $TLD)).Content -split '\n'
        $Status = ($Query | Where-Object {$_.StartsWith('status:      ')}).TrimStart('status:      ')
        [string]$Created = (($Query | Where-Object {$_.StartsWith('created:      ')}).TrimStart('created:      ') | Get-Date -Format $DateFormat)
        [string]$Changed = (($Query | Where-Object {$_.StartsWith('changed:      ')}).TrimStart('changed:      ') | Get-Date -Format $DateFormat)
        $NServers = ($Query | Where-Object {$_.StartsWith('nserver:      ')}).TrimStart('nservers: ')
        $NServersDomain = $NServers | ForEach-Object {
            if ($_ -match $PatternDomain) {
                $Matches[0]
            }
        }
        $NServersIpv4 = $NServers | ForEach-Object {
            if ($_ -match $PatternIpv4) {
                $Matches[0]
            }
        }
        $NServersIpv6 = $NServers | ForEach-Object {
            if ($_ -match $PatternIpv6) {
                $Matches[0]
            }
        }
        $WholeObject = [PSCustomObject]@{
            TLD =     $TLD
            Status =  $Status
            Created = [string]$Created
            Changed = [string]$Changed
            DNS =     @($NServersDomain)
            Ipv4 =    @($NServersIpv4)
            Ipv6 =    @($NServersIpv6)
        }
        $WholeObject
    }
    $WhoisLookup
}

function CheckWhoisServerInfo {
    $WhoisServerInfo = foreach ($WhoServer in $WhoisServers) {
        $DomainServerInfo = foreach ($DomainServer in $WhoServer.DNS) {
            $RootDomain = ($DomainServer -split '\.' | Select-Object -Last 2) -join '.'
            #Note: Dedup DNS whois servers here
            Write-Host "Checking $($WhoServer.TLD) for server at $($RootDomain)"
            $Query = ((Invoke-WebRequest -UseBasicParsing ($WhoisInfoSource + $RootDomain)).Content | ConvertFrom-Json).Domain
            if ($null -ne $Query.expiration_date) {
                [string]$Expires = [datetime]($Query.expiration_date) | Get-Date -Format $DateFormat
            } else {
                [string]$Expires = 'NA'
            }
            $WholeObject = [PSCustomObject]@{
                TLD = $WhoServer.TLD
                Created = $WhoServer.Created
                Changed = $WhoServer.Changed
                WhoIsServer = $RootDomain
                Expiration = $Expires
            }
            $WholeObject
        }
        $DomainServerInfo
    }
}

#Run
#----------------

Write-Host '
==============
Whois Servers
=============
'

$WhoisServers = GetWhoisServers
$WhoisServerInfo = CheckWhoisServerInfo
