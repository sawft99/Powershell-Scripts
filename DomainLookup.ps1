#Lookup every possible TLD of a domain
$DomainRoot = "twitter"
#You could specify multiple DNS servers here if you wanted
$DNSServer = @('8.8.8.8')
$OutputFolder = "C:\Output"

#Premade variables
$TLDSource = "https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
$AllTLD = (Invoke-WebRequest -UseBasicParsing -Uri $TLDSource).content -split "\n"
$DNSTypes = @('A_AAAA','NS','CNAME','SOA','MX','TXT','DS','RRSIG','NSEC','DNSKEY')
$WHOISURL = "https://www.whois.com/whois/"
#Text document has a header so index starts at 1 and there are extra spaces at the end thus the '- 2'
$AllTLD = $AllTLD[1..($AllTLD.Count - 2)]
$Resolved = @()
$ResolvedNOIP = @()
$Collision = @()
$Unresolved = @()

#DNSLookup
#Green if found, yellow if no ip, collision, or not yet official, red if nothing found
Clear-Host

foreach ($TLD in $AllTLD) {
    $FullDomain = ($DomainRoot + "." + $TLD)
    #Write-Host "Looked up " -NoNewline
    $Lookup = foreach ($Type in $DNSTypes) {
        $Result = Resolve-DnsName $FullDomain -Server $DNSServer -DnsOnly -Type $Type -ErrorAction SilentlyContinue
        if (($Type -ne "SOA" ) -and ($Result.Type -eq "SOA")) {$Result = $null}
        if (($Result -ne $null) -and ($Result.count -gt 0)) {$Result | Export-Csv -Path "$OutputFolder\$Type.csv" -Append -NoClobber -NoTypeInformation -Force}
        $Result
    }
    $Lookup = $Lookup | Select-Object -Unique
    Write-Host "Looked up " -NoNewline
    if (($Lookup.IPAddress.count -gt 0) -or ($Lookup.IP4Address -gt 0) -or ($Lookup.IP6Address -gt 0)) {
        if (($Lookup.IPAddress -eq "127.0.53.53") -or ($Lookup.IP4Address -eq "127.0.53.53")) {
            Write-Host -ForegroundColor Yellow "$FullDomain - Collision/Unofficial"
            $Collision += $FullDomain
        } else {
            Write-Host -ForegroundColor Green "$FullDomain"
            $Resolved += $FullDomain
        }
    } else {
        if ($Lookup.count -gt 0) {
            Write-Host -ForegroundColor Yellow "$FullDomain - No IP"
            $ResolvedNOIP += $FullDomain
        } else {
            Write-Host -ForegroundColor Red "$FullDomain"
            $Unresolved += $FullDomain
        }
    }
}

Clear-Host
Write-Host ("Resolved Domains (" + ($Resolved.count) + "):")
Write-Host ""
$Resolved
Write-Host ""
Write-Host ("Resolved Domains NOIP (" + ($ResolvedNOIP.count) + "):")
Write-Host ""
$ResolvedNOIP
Write-Host ""
Write-Host ("Collision/Unofficial Domains (" + ($Collision.count) + "):")
Write-Host ""
$Collision
Write-Host ""
Write-Host ("Unresolved Domains (" + ($Unresolved.count) + "):")
Write-Host ""
$Unresolved
