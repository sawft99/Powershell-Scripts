#Lookup every possible TLD of a domain
$DomainRoot = "twitter"
[IPAddress]$DNSServer = "8.8.8.8"

#Premade variables
$TLDSource = "https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
$AllTLD = (Invoke-WebRequest -UseBasicParsing -Uri $TLDSource).content -split "\n"
#Text document has a header so index starts at 1 and there are extra spaces at the end thus the '- 2'
$AllTLD = $AllTLD[1..($AllTLD.Count - 2)]
$Resolved = @()
$ResolvedNOIP = @()
$Collision = @()
$Unresolved = @()

#DNSLookup
#Green if found and red if not
Clear-Host

foreach ($TLD in $AllTLD) {
    $FullDomain = ($DomainRoot + "." + $TLD)
    Write-Host "Looked up " -NoNewline
    $Lookup = Resolve-DnsName $FullDomain -Server $DNSServer -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction SilentlyContinue
    if (($Lookup.IPAddress.count -gt 0) -or ($Lookup.IP4Address -gt 0) -or ($Lookup.IP6Address -gt 0)) {
        if (($Lookup.IPAddress -eq "127.0.53.53") -or ($Lookup.IP4Address -eq "127.0.53.53")) {
            Write-Host -ForegroundColor Yellow "$FullDomain - Collision"
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
Write-Host ("Unresolved Domains (" + ($Unresolved.count) + "):")
Write-Host ""
$Unresolved
Write-Host ""
Write-Host ("Collision Domains (" + ($Collision.count) + "):")
Write-Host ""
$Collision
