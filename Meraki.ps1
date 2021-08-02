#Made for PS7!
$APIKey = #"APIKEY"
$OrgID = #"ORGID"
$APIHeader = "X-Cisco-Meraki-API-Key"
#$APIRequestURL = "https://api.meraki.com/api/v1/organizations/$OrgID/apiRequests"
$NetworksListURL = "https://api.meraki.com/api/v1/organizations/$OrgID/networks"
$NetworkUrl = "https://api.meraki.com/api/v1/networks"
$DevicesURL = "https://api.meraki.com/api/v1/devices"

#Invoke-WebRequest -Headers @{$APIHeader = $APIKey} -Uri $APIRequestURL -SessionVariable MerakiSession -ErrorVariable APITest
#if ($APITest.message -match "Invalid API Key") {
#    Write-Host "Bad API Key. Exiting..."
#    Exit
#}
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
    $SiteDevices = ForEach ($Something in $Test3.id) {(Invoke-WebRequest -Method Get -WebSession $MerakiSession -Uri ("$NetworkURL/" + $Something + "/devices" )) | ConvertFrom-Json}
}
$Test3 | Where-Object -Property Line -eq $NetworkSelect | Format-Table -Property Line, Name, ID

function AllTasks {
    Write-Host "
Choose a task:

1. Get all AP's info in organization (takes some time)
2. Reboot all AP's in organization (takes some time)

"
}
function NetTasks {
Write-Host "

1. Get all AP's info at site
2. Get specific AP info at site
3. Reboot specific AP at site
4. Reboot all AP's at site
5. Get client list from all APs at site
6. Get client list from specific AP at site

"
}
if ($NetworkSelect -match "all") {
    AllTasks
    do {
        $AllTaskSelect = Read-Host -Prompt 'Select a task'
        if ($AllTaskSelect -notin 1..3) {
            Write-Host 'Pick a valid option'
        }
    }
    while ($AllTaskSelect -notin 1..3) {
    }
}
else {
    NetTasks
    do {
        $NetTaskSelect = Read-Host -Prompt 'Select a task'
        if ($NetTaskSelect -notin 1..6) {
            Write-Host 'Pick a valid option'
        }
    }
    while ($NetTaskSelect -notin 1..6) {
    }
}

if ($null -ne $AllTaskSelect) {
    switch ($AllTaskSelect) {
        1 {
            $SiteDevices = ForEach ($Network in $Test3) {
                Write-Progress -Activity "Fetching Info" -Status "Gathering info from"$Network.Name""
                Invoke-WebRequest -Method Get -WebSession $MerakiSession -Uri ("$NetworkURL/" + $Network.id + "/devices")
            }
            $SiteDevices | Format-Table name, LanIP, Mac, Serial, Model
        }
        2 {
            ForEach ($Network in $Test3) {
                $SiteDevices = Invoke-WebRequest -Method Get -WebSession $MerakiSession -Uri ("$NetworkURL/" + $Network.id + "/devices") | ConvertFrom-Json
                ForEach ($AP in $SiteDevices) {
                    Write-Progress -Activity "Rebooting devices..." -PercentComplete ($i/$Test3.line.count)
                    Write-Host Rebooting $AP.name AP at $Network.name
                    Invoke-WebRequest -Method Post -WebSession $MerakiSession -Uri ("$DevicesURL/" + $AP.serial + "/reboot") | Out-Null
                }                
            }
        }
    }
}

if ($null -ne $NetTaskSelect) {
    switch ($NetTaskSelect) {
        1 {
            $SiteDevices | Format-Table -Property Name, LanIP, MAC, Serial, Model
        }
        2 {
            $DeviceTableCount = 1
            $SiteDevices | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name Line -Value $DeviceTableCount -Force
                $DeviceTableCount++
            }
            $SiteDevices | Sort-Object -Property name | Format-Table -Property Line, Name, LanIP, MAC, Serial, Model
            Write-Host ''
            do {
                $APLineSelect = Read-Host -Prompt "Select a specifc AP to get info from"
            }
            while ($APLineSelect -notin $SiteDevices.Line) {
            }
            $APSelect = $SiteDevices | Where-Object -Property line -eq $APLineSelect
            Write-Host "Info for" $APSelect.Name "AP"
            $APSelect | Format-Table -Property Name, LanIP, MAC, Serial, Model
        }
        3 {
            $DeviceTableCount = 1
            $SiteDevices | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name Line -Value $DeviceTableCount -Force
                $DeviceTableCount++
            }
            $SiteDevices | Sort-Object -Property name | Format-Table -Property Line, Name, LanIP, MAC, Serial, Model
            Write-Host ''
            do {
                $APLineSelect = Read-Host -Prompt "Select an AP to reboot"
            }
            while ($APLineSelect -notin $SiteDevices.Line) {
            }
            $APSelect = $SiteDevices | Where-Object -Property line -eq $APLineSelect
            $APSelectSerial = $APSelect.Serial
            Write-Host "Rebooting" $APSelect.Name "AP"
            Invoke-WebRequest -Method Post -WebSession $MerakiSession -Uri ("$DevicesURL/" + $APSelectSerial  + "/reboot") | ConvertFrom-Json
        }
        4 {
            ForEach-Object -InputObject $SiteDevices {
                Write-Host "Rebooting:" $_.name "AP"
                Invoke-WebRequest -Method Post -WebSession $MerakiSession -Uri ("$DevicesURL/" + $_.serial + "/reboot") | ConvertFrom-Json
            }
        }
        5 {
            $ClientInfo = foreach ($AP in $SiteDevices) {
                Invoke-WebRequest -method get -Uri ("$DevicesURL/" + $AP.Serial + "/clients") -WebSession $MerakiSession | ConvertFrom-Json
            }
            Write-Host "Clients for Network" $Test3.Name 
            $ClientInfo | Sort-Object -Property Description | Format-table -Property Description, ip, mac, user
        }
        6 {
            $DeviceTableCount = 1
            $SiteDevices | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name Line -Value $DeviceTableCount -Force
                $DeviceTableCount++
            }
            $SiteDevices | Sort-Object -Property name | Format-Table -Property Line, Name, LanIP, MAC, Serial, Model
            Write-Host ''
            do {
                $APLineSelect = Read-Host -Prompt "Select an AP to get clients from"
            }
            while ($APLineSelect -notin $SiteDevices.Line) {
            }
            $APSelect = $SiteDevices | Where-Object -Property line -eq $APLineSelect
            $APSelectSerial = $APSelect.Serial
            $ClientInfo = Invoke-WebRequest -method get -Uri ("$DevicesURL/" + $APSelectSerial + "/clients") -WebSession $MerakiSession | ConvertFrom-Json
            Write-Host "Clients for" $APSelect.Name "AP"
            $ClientInfo | Sort-Object -Property Description | Format-table -Property Description, ip, mac, user
        }
    }
}
