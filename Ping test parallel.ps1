#MADE FOR PS7!
#Pings in parallel. Reports to a text file and to console.
#$CSV is meant to have a field labeled "IP_Address". This can be changed as needed.

#Variables
$OutLocation = #Locaiton
$Results = #$OutLocation\Results.txt
$CSV = #CSV File
$Low = 50
$Med = 30
$High = 20
$ShortPingAmount = 50
$LongPingAmount = 250

#Create PSobject with ips parsed from CSV
$Custom1 = Import-Csv $CSV | ForEach-Object {[PSCustomObject]@{
    'IPaddress' = $_.IP_Address}
}

#Shorten Custom1 Object
$Custom2 = $Custom1.IPAddress

#Short or Long test
Write-Host "

Options:

1. Short test ($ShortPingAmount pings)
2. Long test ($LongPingAmount pings)
"
do {
    $ShortOrLong = Read-Host -Prompt "Select an option"
    if ($ShortOrLong -notin 1..2) {
        Write-Warning "Please pick a valid option."
    }
}
while ($ShortOrLong -notin 1..2)
Write-Host ""

#Ask for sensitivity level
do {
    Write-Host "
Sensitivity Options:

1. Low (>=$Low ms)
2. Medioum (>=$Med ms)
3. High (>=$High ms)
4. Do not report on latency
"
    $LatencyPick = Read-Host -Prompt "Select a latency option"
    if ($LatencyPick -notin 1..4) {
        Write-Warning "Please pick a valid option"
    }
}
while ($LatencyPick -notin 1..4)

#Parallel ping. Results recorded to each appropriate file
if ($ShortOrLong -eq 1) {
    Write-Host "Running short ping test..."
    Write-Host ""
    Write-Host "Noticed issues:"
    Write-Host ""
    $Custom2 | ForEach-Object -ThrottleLimit 20 -Verbose -Parallel {
        $AliveTest = Test-Connection -Count 3 -Ping -IPv4 -DontFragment -TargetName $_
        $AliveTest | Out-File -FilePath $using:OutLocation\$_.txt
        if ($AliveTest.Status -notcontains "Success") {
            Write-Warning "$_ is not responding or has high latency. Skipping."
            Write-Output "$_ is not responding or has high latency. Skipping." | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
        }
        else {
            $PingTest = Test-Connection -Count $using:ShortPingAmount -Ping -IPv4 -DontFragment -TargetName $_
            $PingTest | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            $IPFile = "$using:OutLocation\$_.txt"
            switch ($using:LatencyPick) {
                1 {
                    if (((($PingTest.Latency) -ge $using:Low).count/$using:ShortPingAmount) -gt 0) {
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Low).count/$using:ShortPingAmount).ToString("P") + " of packets over $using:Low ms"
                    }
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Low).count/$using:ShortPingAmount).ToString("P") + " of packets over $using:Low ms" | Out-File -FilePath $IPFile -Force -Append
                }
                2 {
                    if (((($PingTest.Latency) -ge $using:Med).count/$using:ShortPingAmount) -gt 0) {
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Med).count/$using:ShortPingAmount).ToString("P") + " of packets over $using:Med ms"
                    }    
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Med).count/$using:ShortPingAmount).ToString("P") + " of packets over $using:Med ms" | Out-File -FilePath $IPFile -Force -Append
                }
                3 {
                    if (((($PingTest.Latency) -ge $using:High).count/$using:ShortPingAmount) -gt 0) {
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:High).count/$using:ShortPingAmount).ToString("P") + " of packets over $using:High ms"
                    }        
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:High).count/$using:ShortPingAmount).ToString("P") + " of packets over $using:High ms" | Out-File -FilePath $IPFile -Force -Append
                }
                4 {
                    return
                }
            }
        }
    }
}

if ($ShortOrLong -eq 2) {
    Write-Host "Running long ping test..."
    Write-Host ""
    Write-Host "Noticed issues:"
    Write-Host ""
    $Custom2 | ForEach-Object -ThrottleLimit 20 -Verbose -Parallel {
        $AliveTest = Test-Connection -Count 3 -Ping -IPv4 -DontFragment -TargetName $_
        $AliveTest | Out-File -FilePath $using:OutLocation\$_.txt
        if ($AliveTest.status -notcontains "Success") {
            Write-Warning "$_ is not responding or has high latency. Skipping."
            Write-Output "$_ is not responding or has high latency. Skipping." | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
        }
        else {
            $PingTest = Test-Connection -Count $using:LongPingAmount -Ping -IPv4 -DontFragment -TargetName $_
            $PingTest | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            $IPFile = "$using:OutLocation\$_.txt"
            switch ($using:LatencyPick) {
                1 {
                    if (((($PingTest.Latency) -ge $using:Low).count/$using:LongPIngAmount) -gt 0) {
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Low).count/$using:LongPIngAmount).ToString("P") + " of packets over $using:Low ms"
                    }
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Low).count/$using:LongPIngAmount).ToString("P") + " of packets over $using:Low ms" | Out-File -FilePath $IPFile -Force -Append
                }
                2 {
                    if (((($PingTest.Latency) -ge $using:Med).count/$using:LongPIngAmount) -gt 0) {
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Med).count/$using:LongPIngAmount).ToString("P") + " of packets over $using:Med ms"
                    }
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Med).count/$using:LongPIngAmount).ToString("P") + " of packets over $using:Med ms" | Out-File -FilePath $IPFile -Force -Append
                }
                3 {
                    if (((($PingTest.Latency) -ge $using:High).count/$using:LongPIngAmount) -gt 0) {
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:High).count/$using:LongPIngAmount).ToString("P") + " of packets over $using:High ms"
                    }
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:High).count/$using:LongPIngAmount).ToString("P") + " of packets over $using:High ms" | Out-File -FilePath $IPFile -Force -Append
                }
                4 {
                    return
                }
            }
        }
    }
}

#Location and name of results
$Files = Get-ChildItem $OutLocation

#Write result to host/console (Reports issues only)
foreach ($File in $Files) {
    $Content = Get-Content -Path $File.FullName
    $Filename = $File.BaseName
    if ("$Content" -match 'TimedOut') {
        if ("$Content" -match 'is not responding or has high latency') {
            Write-Warning "$Filename is not responding or has high latency."
        }
        else {
            Write-Host "$Filename dropped packets."
        }
    }
}
Write-Host ""

#Write results to file (All results recorded)
foreach ($File in $Files) { 
    $Content = Get-Content -Path $File.FullName
    $Filename = $File.BaseName
    if ("$Content" -match 'TimedOut') {
        if ("$Content" -match 'is not responding or has high latency') {
            Write-Output "$Filename is not responding or has high latency." | Out-file -Path $Results -Force -Append
        }
        else {
            Write-Output "$Filename dropped packets." | Out-file -Path $Results -Force -Append
        }
    }
    else {
        Write-Output "$Filename is ok. Check for latency." | Out-File -Path $Results -Force -Append
    }
}
Write-Host "All results recorded to $OutLocation\Results.txt."
Write-Host ""
