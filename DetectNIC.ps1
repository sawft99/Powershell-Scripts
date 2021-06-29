#Get Net adapter info. Filters for only physical wireless interfaces. The two properties are each assigned to variables for more desired output for Kaseya to work with.
#Just reporting the properties directly from $adapterinfo will include header info that we don't want when parsing the generated text files.

$OutLocation = #Location

$adapterinfo = Get-NetAdapter -Physical | Where-Object -Property MediaType -like "*802.11*" | Select-Object -Property InterfaceDescription,DriverVersion
$NICName = $adapterinfo.InterfaceDescription
$DriverVersion = $adapterinfo.DriverVersion

if ($null -ne $NICName) {
    $NICName | Out-File $OutLocation\NICName.txt
    }

if ($null -ne $DriverVersion) {
    $DriverVersion | Out-File $OutLocation\NICDriverVersion.txt
    }