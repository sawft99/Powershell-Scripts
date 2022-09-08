#Removes Sonicwall Connect Tunnel fully.

#MSI based removal
$Regs = @('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\')
$Installs = foreach ($Reg in $Regs) {
    Get-ChildItem -Path $Reg | Get-ItemProperty | Where-Object -Property DisplayName -Like "*Connect Tunnel*" | Where-Object -Property PSChildName -Match "{"
}
foreach ($Install in $Installs) {
    $UninstallString = $Install.PSChildName
    Start-Process  -Wait -NoNewWindow -FilePath C:\Windows\System32\msiexec.exe -ArgumentList "/x $UninstallString", "/quiet", "/norestart"
}

#Last resort if reg search yields 0
#$RAWDATA = get-wmiobject Win32_Product | Where-Object -Property Name -Like "Connect Tunnel"
#$CTGUID = $RAWDATA.IdentifyingNumber
#foreach ($GUID in $CTGUID) {Start-Process -FilePath C:\Windows\System32\msiexec.exe -ArgumentList "/x $GUID", "/quiet", "/norestart" -Wait -NoNewWindow}

#Removes any non MSI based installs
$InstallLoc = Get-ChildItem "C:\ProgramData\Package Cache"
$InstallLocShort = $InstallLoc.Name
foreach ($Folder in $InstallLocShort) {
    if ((Test-Path -Path "C:\ProgramData\Package Cache\$Folder\MCTSetup.exe") -eq $true) {
        Start-Process -Wait -NoNewWindow -FilePath ('C:\ProgramData\Package Cache\' + $Folder + '\MCTSetup.exe') -ArgumentList "/quiet", "/norestart", "/uninstall"
        if ((Test-Path -Path "C:\ProgramData\Package Cache\$Folder\MCTSetup.exe") -eq $true) {
            Remove-Item -Recurse -Force -Path ('C:\ProgramData\Package Cache\' + $Folder)
        }
    }
}
foreach ($Folder in $InstallLocShort) {
    if ((Test-Path -Path "C:\ProgramData\Package Cache\$Folder\ConnectTunnel.msi") -eq $true) {
        Start-Process -Wait -NoNewWindow -FilePath ('C:\Windows\System32\msiexec.exe') -ArgumentList "/x `"C:\ProgramData\Package Cache\$Folder\ConnectTunnel.msi`" /quiet /norestart"
        if ((Test-Path -Path "C:\ProgramData\Package Cache\$Folder\ConnectTunnel.msi") -eq $true) {
            Remove-Item -Recurse -Force -Path ("C:\ProgramData\Package Cache\$Folder")
        }
    }
}

if ((Test-Path -Path "C:\Program Files\SonicWall\Modern Connect Tunnel") -eq $true) {
    Remove-Item -Recurse -Force -Path ("C:\Program Files\SonicWall\Modern Connect Tunnel")
}

#Clear appdata of old profile/config
$Users = Get-ChildItem C:\Users\ -Name
foreach ($User in $Users) {
    if ((Test-Path C:\Users\$User\Appdata\Local\Sonicwall -filter *snwl*) -eq $true) {
        if ((Get-ChildItem C:\Users\$User\AppData\Local\SonicWall -filter *SnwlConnect*).Length -gt 0) {
            $SnwlFolder = Get-ChildItem C:\Users\$User\AppData\Local\SonicWall -filter *SnwlConnect*
            $SnwlFolderFull = $SnwlFolder.FullName
            foreach ($Folder in $SnwlFolderFull) {
                Remove-Item -Path $Folder -Recurse -Force
            }
        }
        if ((Test-Path C:\Users\$User\Appdata\Local\Sonicwall\SnwlVpn) -eq $true) {
            Remove-Item C:\Users\$User\Appdata\Local\Sonicwall\SnwlVpn -Recurse -Force
        }
    }
}
