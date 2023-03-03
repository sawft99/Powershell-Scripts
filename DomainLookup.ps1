#Lookup every possible TLD of a domain
$DomainRoot = "example"

#Premade variables
$TLDSource = "https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
$AllTLD = (Invoke-WebRequest -UseBasicParsing -Uri $TLDSource).content -split "\n"
#Text document has a header so index starts at 1 and extra spaces at the end thus the '- 2'
$AllTLD = $AllTLD[1..($AllTLD.Count - 2)]
$Resolved = @()
$Unresolved = @()

#DNSLookup
#Green if found and red if not
Clear-Host

foreach ($TLD in $AllTLD) {
    $FullDomain = ($DomainRoot + "." + $TLD)
    Write-Host "Looked up " -NoNewline
    $Lookup = Resolve-DnsName $FullDomain -ErrorAction SilentlyContinue
    if ($Lookup.IPAddress.count -gt 0) {
        Write-Host -ForegroundColor Green "$FullDomain"
        $Resolved += $FullDomain
    } else {
        Write-Host -ForegroundColor Red "$FullDomain"
        $Unresolved += $FullDomain
    }
}

Clear-Host
Write-Host Resolved domains:
Write-Host ""
$Resolved
Write-Host""
Write-Host Unresolved domains:
Write-Host ""
$Unresolved
