#Check if VPN is running and restart if not

#Location of Wireguard program
[System.IO.DirectoryInfo]$WireguardDir = "$env:ProgramFiles\Wireguard\"
#Location of Wireguard config file(s)
[System.IO.DirectoryInfo]$ConfigDir = $WireguardDir.FullName + 'Data\ConfigFiles\'
#Locaiton of specific config file for this VPN check
[System.IO.FileInfo]$ConfigFile = $ConfigDir.FullName + 'VPN.conf'
#Whether to check if the IP Wireguard is connecting to is the same as what DNS resolves to
$DNSCheck = $true #or '$false'
#DNS name Wireguard is trying to connect to, will not use DNS cache on client
$VPNDNSName = Resolve-DnsName -DnsOnly -NoHostsFile -Type A -Name 'DOMAIN_NAME.myddns.me'

#------------

Clear-Host

Write-Host '================
VPN Status Check
================'

if (($DNSCheck -ne $true) -and ($DNSCheck -ne $false)) {
    Write-Host '$DNSCheck needs to be $true or $false'
    exit 1
}
if (($WireguardDir.Exists -ne $true) -or ($ConfigDir.Exists -ne $true) -or ($ConfigFile.Exists -ne $true)) {
    Write-Host "
    Missing file or folder
    ---------------------

    WireguardDir = $($WireguardDir.Exists)
    ConfigdDir   = $($ConfigDir.Exists)
    ConfigFile   = $($ConfigFile.Exists)
    "
    exit 1
} else {
    Write-Host ''
    cd $WireguardDir
    $VPNInfo = .\wg.exe show
    if ($null -eq $VPNInfo) {
        Write-Host 'VPN not running, starting...'
        wireguard.exe /installtunnelservice $ConfigFile
        Start-Sleep -Seconds 5
        $VPNInfo = .\wg.exe show
        if ($null -eq $VPNInfo) {
            Write-Host 'Failed to restart VPN'
            exit 1
        } else {
            Write-Host 'VPN back up'
            if ($DNSCheck -ne $true) {
              exit 0
            }
        }
    } else {
        Write-Host 'VPN running, exiting'
        if ($DNSCheck -ne $true) {
          exit 0
        }
    }
}

#DNS Check
if ($DNSCheck -eq $true) {
    $VPNIP = (($VPNInfo | Select-String 'endpoint') -split ': ' -split ':')[1]
    if ($VPNIP -ne $VPNDNSName.IPAddress) {
        Write-Host 'DNS and VPN IP mismatch'
        $WireguardProcs = Get-Process 'wireguard'
        foreach ($Proc in $WireguardProcs) {
            Write-Host "Stopping $($Proc.ProcessName) ($($Proc.Id))"
            Stop-Process -Id $Proc.Id -Force
        }
        Write-Host 'Starting VPN again...'
        Start-Sleep -Seconds 5
        wireguard.exe /installtunnelservice $ConfigFile
    }
} else {
    Write-Host '$DNSCheck not $true, skipping'
    exit 0
}
