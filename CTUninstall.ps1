#Removes Sonicwalls Connect Tunnel since it leaves behind a mess that can cause issues.

#MSI based removal
$RAWDATA = get-wmiobject Win32_Product | Where-Object -Property Name -Like "Connect Tunnel"
$CTGUID = $RAWDATA.IdentifyingNumber
foreach ($GUID in $CTGUID) {Start-Process -FilePath C:\Windows\System32\msiexec.exe -ArgumentList "/x $GUID", "/quiet", "/norestart" -Wait -NoNewWindow}

#Removes any non MSI based installs
$InstallLoc = Get-ChildItem "C:\ProgramData\Package Cache"
$InstallLocShort = $InstallLoc.Name
foreach ($Folder in $InstallLocShort) 
    {if ((Test-Path -Path "C:\ProgramData\Package Cache\$Folder\MCTSetup.exe") -eq "True")
        {Start-Process -Wait -NoNewWindow -FilePath ('C:\ProgramData\Package Cache\' + $Folder + '\MCTSetup.exe') -ArgumentList "/quiet", "/norestart", "/uninstall"}}

#Clear appdata of old profile/config
$Users = Get-ChildItem C:\Users\ -Name
foreach ($User in $Users) 
    {if ((Test-Path -Path C:\Users\$User\appdata\Local\Sonicwall\SnwlConnect) -eq "True")
        {Remove-Item -Path C:\Users\$User\appdata\Local\Sonicwall\SnwlConnect* -Recurse -Force}}
