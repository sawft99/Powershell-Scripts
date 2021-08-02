$APIKey = #"APIKEY"
$OrgID = #"ORGID"
$APIHeader = "X-Cisco-Meraki-API-Key"
$APIRequestURL = "https://api.meraki.com/api/v1/organizations/$OrgID/apiRequests"
$NetworksListURL = "https://api.meraki.com/api/v1/organizations/$OrgID/networks"
$NetworkUrl = "https://api.meraki.com/api/v1/networks"
$DevicesURL = "https://api.meraki.com/api/v1/devices"

$test2 = (Invoke-WebRequest -Headers @{$APIHeader = $APIKey} -Uri $NetworksListURL -SessionVariable MerakiSession).Content | ConvertFrom-Json | Sort-Object -Property Name
$Test2Count = 1
$Test2 | ForEach-Object {
    $_ | Add-Member -MemberType NoteProperty -Name Line -Value $Test2Count -Force
    $Test2Count++
}
$test2 | Format-Table -Property Line, Name, ID

do {
    $NetworkSelect = Read-Host -Prompt 'Select network via line or type "all" for all networks'
    if ($NetworkSelect -notin $Test2.line -or "all") {
        Write-Host "Pick a valid option"
    }
}    
while (!($NetworkSelect -in $test2.line -xor $NetworkSelect -match "all")) {
    }

Write-Host "Gathering info please wait..."
if ($NetworkSelect -match "all") {
    $Test3 = $test2
}
else {
    $Test3 = $Test2 | Where-Object -Property Line -eq $NetworkSelect
    $SiteDevices = ForEach ($Something in $Test3.id) {(Invoke-WebRequest -Headers @{$APIHeader = $APIKey} -Method Get -Uri ("$NetworkURL/" + $Something + "/devices" )) | ConvertFrom-Json}
}
$Test3 | Where-Object -Property Line -eq $NetworkSelect | Format-Table -Property Line, Name, ID
function Tasks {
    Write-Host "
Choose a task:

1. Reboot specific AP at site
2. Reboot all AP's at site
3. Reboot all AP's in organization (takes some time)
4. Get all AP's info at site
5. Get all AP's info in organization (takes some time)

"
    do {
        $global:TaskSelect = Read-Host -Prompt 'Select a task'
        if ($global:TaskSelect -notin 1..6) {
            Write-Host Pick a valid option
        }
    }
    while ($global:TaskSelect -notin 1..6) {
    }
}
Tasks
switch ($global:TaskSelect) {
    1 {
        $DeviceTableCount = 1
        $SiteDevices | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name Line -Value $DeviceTableCount -Force
            $DeviceTableCount++
        }
        $SiteDevices | Sort-Object -Property name | Format-Table -Property Line, Name, LanIP, MAC, Serial, Model
        Write-Host
        do {
            $APLineSelect = Read-Host -Prompt "Select an AP to reboot"
        }
        while ($APLineSelect -notin $SiteDevices.Line) {
        }
        $APSelect = $SiteDevices | Where-Object -Property line -eq $APLineSelect
        $APSelectSerial = $APSelect.Serial
        Write-Host "Rebooting"$APSelect.Name"AP"
        Invoke-WebRequest -Headers @{$APIHeader = $APIKey} -Method Post -Uri ("$DevicesURL" + "/$APSelectSerial"  + "/reboot" ) | ConvertFrom-Json
    }
    2 {
        $DeviceTableCount = 1
        $SiteDevices | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name Line -Value $DeviceTableCount -Force
            $DeviceTableCount++
        }
        $SiteDevices | Sort-Object -Property name | Format-Table -Property Line, Name, LanIP, MAC, Serial, Model
        foreach ($AP in $SiteDevices.Serial) {
            Write-Host "Rebooting"$SiteDevices.Name"AP"
            Invoke-WebRequest -Headers @{$APIHeader = $APIKey} -Method Post -Uri ("$DevicesURL" + "/$AP"  + "/reboot" ) | ConvertFrom-Json
        }
    }
    3 {
        ForEach-Object -InputObject $AllSerials {
            Write-Host "Rebooting:" $Test3.name
            Invoke-WebRequest -Headers @{$APIHeader = $APIKey} -Method Post -Uri "$DevicesURL/" + "$_" + "/reboot"
        }
    }
    4 {
        $SiteDevices | Format-Table -Property Name, LanIP, MAC, Serial
    }
    5 {
        $Test4 = @()
        ForEach ($Something in $Test2) {
            Invoke-WebRequest -Headers @{$APIHeader = $APIKey} -Uri ("https://api.meraki.com/api/v1/networks/" + $Something.id + "/devices" ) | ConvertFrom-Json
            $Test4Table = "" | Select-Object Name, LanIP, MAC, Serial
            $Test4Table.Name = $Something.Name
            $Test4Table.LanIP = $Something.LanIP
            $Test4Table.Mac = $Something.Mac
            $Test4Table.Serial = $Something.Serial
            $Test4 += $Test4Table
        }
        $Test4
    }
    6 {

    }
}
