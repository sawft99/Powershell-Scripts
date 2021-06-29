#Gets the last few digits of a windows key. Made to work with an external app that would react to the info provided.

$OutLocation = #Location
$key = cscript C:\windows\system32\slmgr.vbs /dlv | findstr.exe /s "Partial"
$key.Trim("Partial Product Key:") | Out-File -FilePath $OutLocation\winkeypart.txt
