#Finds Chromes GUID and stored it into a registry key.
#Made to have reg key read from an outside program at a later time.

$RAWDATA = get-wmiobject Win32_Product | Where-Object -Property Name -Like "*chrome*"
$ChromeGUID = $RAWDATA.IdentifyingNumber -replace "{" -replace "}"
New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Google\Chrome -Name ChromeGUID -PropertyType String -Value $ChromeGUID -Force
