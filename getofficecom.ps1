#Made to locate the old office compatibility viewers. External reacts to the info provided.

$OutLocation = #Locaiton
$OfficeCheck = get-wmiobject Win32_Product | Where-Object -Property IdentifyingNumber -EQ "{90120000-0020-0409-0000-0000000FF1CE}"
$OfficeCheck | Out-File -FilePath $OutLocation\officecheck.txt
