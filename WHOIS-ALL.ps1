#Lookup every WhoIs server and some info
#Premade variables
$TLDSource = "https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
$WHOISSource = 'https://www.iana.org/whois?q='
$WhoisInfoSource = 'https://who-dat.as93.net/'
#User variables
[System.IO.DirectoryInfo]$OutputFolder = 'C:\Output'
$DateFormat = 'yyyy-MM-dd'
[int32]$Delay = 0
[int32]$Timeout = 3

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

$AllTLD = (Invoke-WebRequest -UseBasicParsing -Uri $TLDSource).content -split "\n"
#Text document has a header so index starts at 1 and there are extra spaces at the end thus the '- 2'
$AllTLD = $AllTLD[1..($AllTLD.Count - 2)]

function GetWhoisServers {
    $PatternDomain = '^[^\s]+\.[^\s]+'
    $PatternIpv4 = '\b(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
    $PatternIpv6 = '\b(?:(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}:(?:[0-9a-fA-F]{1,4}:){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}:(?:[0-9a-fA-F]{1,4}:){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}:(?:[0-9a-fA-F]{1,4}:){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}:(?:[0-9a-fA-F]{1,4}:){1,5}|[0-9a-fA-F]{1,4}:((?:[0-9a-fA-F]{1,4}:){1,6}|:)|:((?:[0-9a-fA-F]{1,4}:){1,7}|:)|fe80:(?:[0-9a-fA-F]{0,4}:){0,4}%[0-9a-zA-Z]{1,}|::(?:[0-9a-fA-F]{1,4}:){0,5}[0-9a-fA-F]{1,4}|::(?:[0-9a-fA-F]{1,4}:){1,6}|(?:[0-9a-fA-F]{1,4}:){1,7}:|:(?:[0-9a-fA-F]{1,4}:){1,7})\b'
    $WhoisLookup = foreach ($TLD in $AllTLD) {
        $NServersDomain = $null
        $NServersIpv4 = $null
        $NServersIpv6 = $null
        $Query = $null
        try {
            Write-Host "Looking up $TLD..."
            $Query = (Invoke-WebRequest -UseBasicParsing -TimeoutSec $Timeout -Uri ($WHOISSource + $TLD)).Content -split '\n'
            Start-Sleep $Delay
            if ($null -eq $Query) {
                #Write-Host -ForegroundColor Red ' | Failed/Timed Out'
            }
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
        } catch {
            if ($null -eq $Query) {
                #Write-Host -ForegroundColor Red ' | Failed/Timed Out'
            }
            $WholeObject = [PSCustomObject]@{
                TLD =     $TLD
                Status =  'Error'
                Created = 'Error'
                Changed = 'Error'
                DNS =     'Error'
                Ipv4 =    'Error'
                Ipv6 =    'Error'
            }
        } finally {
            $WholeObject
        }
    }
    $WhoisLookup
}

function CheckWhoisServerInfo {
    $WhoisServerInfo = foreach ($WhoServer in $WhoisServers) {
        $DomainServers = @()
        $DomainServerInfo = @()
        $DomainServers = foreach ($DNSServer in $WhoServer.DNS) {
            $DNSServerSplit = ($DNSServer -split '\.' | Select-Object -Last 2) -join '.'
            $DNSServerSplit
        }
        $DomainServers = ($DomainServers | Group-Object).Name
        #$DomainServerInfo = foreach ($DomainServer in $WhoServer.DNS) {
        $DomainServerInfo = foreach ($DomainServer in $DomainServers) {
            $Query = $null
            $Expires = $null
            $ExpireRaw = $null
            $RootDomain = $null
            $RootDomain = ($DomainServer -split '\.' | Select-Object -Last 2) -join '.'
            Write-Host "Checking $($WhoServer.TLD) for server at $($RootDomain)"
            try {
                $Query = ((Invoke-WebRequest -UseBasicParsing -TimeoutSec $Timeout -Uri ($WhoisInfoSource + $RootDomain)).Content | ConvertFrom-Json).Domain
                if ($null -eq $Query) {
                    #Write-Host -ForegroundColor Red '| Failed'
                }
                try {
                    if ($null -ne $Query.expiration_date) {
                        [string]$Expires = [datetime]($Query.expiration_date) | Get-Date -Format $DateFormat
                        [string]$ExpireRaw = $Query.expiration_date
                    } else {
                        [string]$Expires = 'NA'
                        [string]$ExpireRaw = 'NA'
                    }
                } catch {
                    Write-Host -ForegroundColor Red 'Error converting date'
                    [string]$Expires = 'Error'
                    [string]$ExpireRaw = $Query.expiration_date
                }
                $WholeObject = [PSCustomObject]@{
                    TLD = $WhoServer.TLD
                    Created = $WhoServer.Created
                    Changed = $WhoServer.Changed
                    WhoIsServer = $RootDomain
                    Expiration = $Expires
                    ExpirationRaw = $ExpireRaw
                }
            } catch {
                $WholeObject = [PSCustomObject]@{
                    TLD = $WhoServer.TLD
                    Created = $WhoServer.Created
                    Changed = $WhoServer.Changed
                    WhoIsServer = $RootDomain
                    Expiration = 'Error'
                    ExpirationRaw = $ExpireRaw
                }
            } finally {
                $WholeObject
            }
        }
        $DomainServerInfo
    }
    $WhoisServerInfo
}

#Run
#----------------

Clear-Host

$WhoisServers = GetWhoisServers
$WhoisServerInfo = CheckWhoisServerInfo

Write-Host '
=============
Whois Servers
=============
'

$ExpiredWhoisServers = ($WhoisServerInfo | Where-Object -Property Expiration -le (Get-Date -Format $DateFormat)).WHOISSERVER
$ExpiredWhoisServersDetailed = $WhoisServerInfo | Where-Object -Property WhoIsServer -in $ExpiredWhoisServers

$ExpiredWhoisServersDetailed | Format-Table
