#Made for PS7!
$APIKey = #"APIKEY"
$OrgID = #"ORGID"
$APIHeader = "X-Cisco-Meraki-API-Key"
$OrgURL = "https://api.meraki.com/api/v1/organizations/$OrgID"
$NetworksListURL = "https://api.meraki.com/api/v1/organizations/$OrgID/networks"
$NetworkUrl = "https://api.meraki.com/api/v1/networks"
$DevicesURL = "https://api.meraki.com/api/v1/devices"

$NetworkFetch = (Invoke-WebRequest -Headers @{$APIHeader = $APIKey} -Uri $NetworksListURL -SessionVariable MerakiSession).Content | ConvertFrom-Json | Sort-Object -Property Name

$NetworkFetchCount = 1
$NetworkFetch | ForEach-Object {
    $_ | Add-Member -MemberType NoteProperty -Name Line -Value $NetworkFetchCount -Force
    $NetworkFetchCount++
}
$NetworkFetch | Format-Table -Property Line, Name, ID

do {
    $NetworkLineSelect = Read-Host -Prompt 'Select network via line or type "all" for all networks'
    if ($NetworkLineSelect -notin $NetworkFetch.line -xor $NetworkLineSelect -match "all") {
        Write-Host "Pick a valid option"
    }
} while (!($NetworkLineSelect -in $NetworkFetch.line -xor $NetworkLineSelect -match "all"))

Write-Host "Gathering info please wait..."
if ($NetworkLineSelect -match "all") {
    $NetworkSelect = $NetworkFetch
}
else {
    $NetworkSelect = $NetworkFetch | Where-Object -Property Line -eq $NetworkLineSelect
    $SiteDevices = ForEach ($Something in $NetworkSelect.id) {(Invoke-WebRequest -Method Get -WebSession $MerakiSession -Uri ("$NetworkURL/" + $Something + "/devices" )) | ConvertFrom-Json}
}
$NetworkSelect | Where-Object -Property Line -eq $NetworkLineSelect | Format-Table -Property Line, Name, ID

function AllTasks {
    Write-Host "Choose a task:

1. Get all AP's info in organization (takes some time)
2. Reboot all AP's in organization (takes some time)
"
}
function NetTasks {
Write-Host " Choose a task:

1. Get all AP's info at site
2. Get specific AP info at site
3. Reboot specific AP at site
4. Reboot all AP's at site
5. Get client list from all APs at site
6. Get client list from specific AP at site
7. Blink LED's on AP
"
}
if ($NetworkLineSelect -match "all") {
    AllTasks
    do {
        $AllTaskSelect = Read-Host -Prompt 'Select a task'
        if ($AllTaskSelect -notin 1..2) {
            Write-Host 'Pick a valid option'
        }
    }
    while ($AllTaskSelect -notin 1..2) {
    }
}
else {
    NetTasks
    do {
        $NetTaskSelect = Read-Host -Prompt 'Select a task'
        if ($NetTaskSelect -notin 1..7) {
            Write-Host 'Pick a valid option'
        }
    }
    while ($NetTaskSelect -notin 1..7) {
    }
}

if ($null -ne $AllTaskSelect) {
    switch ($AllTaskSelect) {
        1 {
            #$SiteDevices = Invoke-WebRequest -Method Get -WebSession $MerakiSession -Uri ("$OrgURL" + "/devices") | ConvertFrom-Json
            $SiteDevices = Invoke-WebRequest -Method Get -WebSession $MerakiSession -Uri ("$OrgURL" + "/devices/statuses") | ConvertFrom-Json
            $DeviceCount = (Invoke-WebRequest -Method get -WebSession $MerakiSession -Uri ("$OrgURL/" + "/devices") | ConvertFrom-Json).count
            $LineCount = 1
            $ProgressCount = 1
            ForEach ($AP in $SiteDevices) {
                $ProgressPreference = 'Continue'
                $Percent = [math]::round(($ProgressCount/$DeviceCount)*100)
                Write-Progress -Activity "Gathering info for all AP's" -Status "$Percent% done" -PercentComplete $Percent
                $ProgressPreference = 'SilentlyContinue'
                Add-Member -InputObject $AP -MemberType NoteProperty -Name Line -Value $LineCount
                $LineCount ++
                $APNetwork = Invoke-WebRequest -Method Get -WebSession $MerakiSession -Uri ("$NetworkURL/" + $AP.NetworkID) | ConvertFrom-Json
                Add-Member -InputObject $AP -MemberType NoteProperty -Name NetworkName $APNetwork.Name
                $ProgressCount ++
            }
            $SiteDevices | Format-Table -Property Line, Name, Serial, LANIP, Mac, Model, NetworkName, PublicIP, Status 
            #address, ConfigurationUpdatedAt
        }
        2 {
            $ProgressCount = 1
            $DeviceCount = (Invoke-WebRequest -Method get -WebSession $MerakiSession -Uri ("$OrgURL/" + "/devices") | ConvertFrom-Json).count
            ForEach ($Network in $NetworkSelect) {
                $SiteDevices = Invoke-WebRequest -Method Get -WebSession $MerakiSession -Uri ("$NetworkURL/" + $Network.id + "/devices") | ConvertFrom-Json
                ForEach ($AP in $SiteDevices) {
                    $ProgressPreference = 'Continue'
                    $Percent = [math]::round(($ProgressCount/$DeviceCount)*100)
                    Write-Progress -Activity "Rebooting all AP's" -Status "$Percent% done" -PercentComplete $Percent
                    Write-Host Rebooting $AP.name AP at $Network.name
                    $ProgressPreference = 'SilentlyContinue'
                    Invoke-WebRequest -Method Post -WebSession $MerakiSession -Uri ("$DevicesURL/" + $AP.serial + "/reboot") -MaximumRetryCount 5 | Out-Null
                    $ProgressCount ++
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
            while ($APLineSelect -notin $SiteDevices.Line)
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
            while ($APLineSelect -notin $SiteDevices.Line)
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
            Write-Host "Clients for Network" $NetworkSelect.Name 
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
            while ($APLineSelect -notin $SiteDevices.Line)
            $APSelect = $SiteDevices | Where-Object -Property line -eq $APLineSelect
            $APSelectSerial = $APSelect.Serial
            $ClientInfo = Invoke-WebRequest -method get -Uri ("$DevicesURL/" + $APSelectSerial + "/clients") -WebSession $MerakiSession | ConvertFrom-Json
            Write-Host "Clients for" $APSelect.Name "AP"
            $ClientInfo | Sort-Object -Property Description | Format-table -Property Description, ip, mac, user
        }
        7 {
            $DeviceTableCount = 1
            $SiteDevices | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name Line -Value $DeviceTableCount -Force
                $DeviceTableCount++
            }
            $SiteDevices | Sort-Object -Property name | Format-Table -Property Line, Name, LanIP, MAC, Serial, Model
            Write-Host ''
            do {
                $APLineSelect = Read-Host -Prompt "Select an AP to blink LED's on"
            }
            while ($APLineSelect -notin $SiteDevices.Line)
            $APSelect = $SiteDevices | Where-Object -Property line -eq $APLineSelect
            $APSelectSerial = $APSelect.Serial
            do {
                $LEDLengthPrompt = Read-host -Prompt "Enter # of seconds to blink LED (Between 1 - 120)"
            }
            while ($LEDLengthPrompt -notin 1..120)
            $BlinkForm = @{
                "duration" = $LEDLengthPrompt
                "period"= 100
                "duty" = 10
            }
            Write-Host ''
            Write-Host "Blinking" $APSelect.Name "AP for $LEDLengthPrompt seconds"
            Invoke-WebRequest -Method Post -WebSession $MerakiSession -Uri ("$DevicesURL/" + $APSelectSerial  + "/blinkLeds") -Form $BlinkForm | ConvertFrom-Json | Out-Null
        }
    }
}
