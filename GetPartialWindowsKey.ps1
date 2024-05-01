#Gets the last few characters of a windows key. Option to write to file.

$LogOption = $false
$OutLocation = 'C:\Log'
$OutFile = $OutLocation + '\WinKeyPart.txt'

#----------------

Clear-Host

Write-Host '
-------------------
Partial Windows Key
-------------------
'

if (($LogOption -ne $true) -and ($LogOption -ne $false)) {
    Write-Host -ForegroundColor Red 'Select either $true or $false for the $LogOption value
    '
    exit 1
} elseif ((Test-Path $OutLocation) -ne $true) {
    Write-Host -ForegroundColor Red 'OutLocation folder does not exist
    '
    exit 1
} else {
    $Key = cscript C:\windows\system32\slmgr.vbs /dlv | findstr.exe /s "Partial"
    if ($LogOption -eq $true) {
        $Key | Out-File -FilePath "$OutFile" -Force
    }
    Write-Host $Key
    exit 0
}
