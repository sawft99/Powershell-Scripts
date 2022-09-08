#Finds Chromes GUID and stores it in a registry key.

$RAWDATA = get-wmiobject Win32_Product | Where-Object -Property Name -Like "*chrome*"
$ChromeGUID = $RAWDATA.IdentifyingNumber -replace "{" -replace "}"
New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Google\Chrome -Name ChromeGUID -PropertyType String -Value $ChromeGUID -Force
