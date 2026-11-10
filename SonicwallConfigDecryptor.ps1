#Decrypt Sonicwall .exp settings file
#Made for Windows

#Location of .EXP file to decrypt
$OriginalSettingsFile = "C:\WorkingDirectory\settings.exp"

#Premade variables will do all of the work in the same directory
$OriginalSettings = Get-Content $OriginalSettingsFile
$ParentDirectory = $OriginalSettings.PSParentPath
$TempSettingsFile = "$ParentDirectory\TempSettings.xps"
$DecodedSettingsFile = "$ParentDirectory\TempSettings.txt"
$FinalFile = "$ParentDirectory\DecryptedSettings.txt"

#Trim characters at end so it can be properly decoded
$OriginalSettingsTrim1 = $OriginalSettings.TrimEnd("&&")
$OriginalSettingsTrim1 | Out-File -FilePath $TempSettingsFile

#Decode file
certutil.exe -decode $TempSettingsFile $DecodedSettingsFile

#Change characters in file
$DecodedContent = Get-Content $DecodedSettingsFile
$FinalContent = $DecodedContent.Replace("&", "`n")

#Final decrypted file
$FinalContent | Out-File $FinalFile

#Cleanup
Remove-Item $TempSettingsFile
Remove-Item $DecodedSettingsFile
