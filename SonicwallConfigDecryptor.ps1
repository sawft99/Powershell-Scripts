#Decrypt Sonicwall .exp settings file
#Made for Windows

$OriginalSettingsFile = "C:\WorkingDirectory\settings.exp"
$OriginalSettings = Get-Content $OriginalSettingsFile
$ParentDirectory = $OriginalSettings.PSParentPath
$TempSettingsFile = "$ParentDirectory\TempSettings.xps"
$DecodedSettingsFile = "$ParentDirectory\TempSettings.txt"
$FinalFile = "$ParentDirectory\DecryptedSettings.txt"

$OriginalSettingsTrim1 = $OriginalSettings.TrimEnd("&&")
$OriginalSettingsTrim1 | Out-File -FilePath $TempSettingsFile

certutil.exe -decode $TempSettingsFile $DecodedSettingsFile

$DecodedContent = Get-Content $DecodedSettingsFile
$FinalContent = $DecodedContent.Replace("&", "`n")

$FinalContent | Out-File $FinalFile

Remove-Item $TempSettingsFile
Remove-Item $DecodedSettingsFile
