#Lookup every possible TLD of a domain
$DomainRoot = @('twitter','google','facebook','microsoft')
$DNSServer = @('8.8.8.8')
[System.IO.DirectoryInfo]$OutputFolder = 'C:\Output'

#Premade variables
$DNSTypes = @('A_AAAA','NS','CNAME','SOA','MX','TXT','DS','RRSIG','NSEC','DNSKEY')
$TLDSource = "https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
$AllTLD = (Invoke-WebRequest -UseBasicParsing -Uri $TLDSource).content -split "\n"
#Text document has a header so index starts at 1 and there are extra spaces at the end thus the '- 2'
$AllTLD = ($AllTLD[1..($AllTLD.Count - 2)]).ToUpper()

#---------------

Clear-Host

Write-Host '
=================
Domain TLD Lookup
================='

#Test for parent path
if ($OutputFolder.Exists -eq $false) {
    Write-Host -ForegroundColor Red 'Output folder does not exist
'
    exit 1
}

#DNSLookup
#Green if found, yellow if no ip, collision, or not yet official, and red if nothing found

foreach ($Domain in $DomainRoot) { 
    [System.IO.DirectoryInfo]$DomainFolder = $OutputFolder.FullName + '\' + $Domain
    if ($DomainFolder.Exists -eq $false) {
        New-Item -Path $OutputFolder -Name $Domain.ToUpper() -ItemType Directory | Out-Null
    }
    $Resolved = @()
    $ResolvedNOIP = @()
    $Collision = @()
    $Unresolved = @()
    Write-Host ''
    Write-Host 'Running lookups for: ' -NoNewline && Write-Host -ForegroundColor Cyan $Domain.ToUpper()
    Write-Host ''
    foreach ($TLD in $AllTLD) {
        $FullDomain = ($Domain + "." + $TLD)
        $Lookup = foreach ($Type in $DNSTypes) {
            $Result = Resolve-DnsName $FullDomain -Server $DNSServer -DnsOnly -Type $Type -ErrorAction SilentlyContinue
            if (($Type -ne "SOA" ) -and ($Result.Type -eq "SOA")) {$Result = $null}
            if (($null -ne $Result) -and ($Result.count -gt 0)) {$Result | Export-Csv -Path "$DomainFolder\$Type.csv" -Append -NoClobber -NoTypeInformation -Force}
            $Result
        }
        $Lookup = $Lookup | Select-Object -Unique
        Write-Host "Looked up " -NoNewline
        if (($Lookup.IPAddress.count -gt 0) -or ($Lookup.IP4Address -gt 0) -or ($Lookup.IP6Address -gt 0)) {
            if (($Lookup.IPAddress -eq "127.0.53.53") -or ($Lookup.IP4Address -eq "127.0.53.53")) {
                Write-Host -ForegroundColor Yellow "$($FullDomain.ToUpper()) - Collision/Unofficial"
                $Collision = $Collision + $FullDomain
            } else {
                Write-Host -ForegroundColor Green "$($FullDomain.ToUpper())"
                $Resolved = $Resolved + $FullDomain
            }
        } else {
            if ($Lookup.count -gt 0) {
                Write-Host -ForegroundColor Yellow "$($FullDomain.ToUpper()) - No IP"
                $ResolvedNOIP = $ResolvedNOIP + $FullDomain
            } else {
                Write-Host -ForegroundColor Red "$($FullDomain.ToUpper())"
                $Unresolved = $Unresolved + $FullDomain
            }
        }
    }
    $Resolved     | Out-File -FilePath "$DomainFolder\!Resolved.txt" -Force -Append
    $ResolvedNOIP | Out-File -FilePath "$DomainFolder\!ResolvedNOIP.txt" -Force -Append
    $Collision    | Out-File -FilePath "$DomainFolder\!Collision.txt" -Force -Append
    $Unresolved   | Out-File -FilePath "$DomainFolder\!Unresolved.txt" -Force -Append
}

#Report
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
