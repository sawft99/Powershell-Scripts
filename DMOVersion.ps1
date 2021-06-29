#Checks for version(s) of Nuance's Dragon software and saves it to a text file. Designed use is just to gather info for another external program that reacts to this info.
 
$OutLocaiton = #Locaiton

$DMOVersion = get-wmiobject Win32_Product | Where-Object -Property Name -Like "*dragon*" | Select-Object version
if ($null -ne $DMOVersion.version)
    {$DMOVersion.version -join ", " | Out-File $OutLocaiton\DMOVersion.txt}
