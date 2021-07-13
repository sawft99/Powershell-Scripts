#MADE FOR PS7!
#Pings in parallel. Reports to a text file and to console.
#$CSV is meant to have a field labeled "IP_Address". This can be changed as needed.

Clear-Host

#Variables
$OutLocation = #"C:\Location"
$Results = "$OutLocation\Results.txt"
$CSV = #"C:\CSVFile.csv"
#Note Variables represent thresholds in milliseconds. Reporting will display anything over the values. For example 
#High = 50, will reportin x% of packets over 50 ms
#Med = 30, will  report x% of packets over 30 ms
#Low = 20, will  report x% of packets over 20 ms
#Reporting in the console will create a tabed cascading list to show how much of each condition was met from highest threshold to lowest.

$High = 50
$Med = 30
$Low = 20
$ShortPingAmount = 50
$LongPingAmount = 250

#Create PSobject with ips parsed from CSV
$IPListCSV = Import-Csv $CSV | ForEach-Object {[PSCustomObject]@{
    'IPaddress' = $_.IP_Address}
}

#Shorten IPListCSV Object
$IPList = $IPListCSV.IPAddress

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

#Parallel ping. Results recorded to each appropriate file
if ($ShortOrLong -eq 1) {
    Write-Host "Running short ping test..."
    Write-Host ""
    Write-Host "Noticed issues:"
    Write-Host ""
    $IPList | ForEach-Object -ThrottleLimit 20 -Verbose -Parallel {
        $AliveTest = Test-Connection -Count 3 -Ping -IPv4 -DontFragment -TargetName $_
        $AliveTest | Out-File -FilePath $using:OutLocation\$_.txt
        if ($AliveTest.Status -notcontains "Success") {
            #Write-Host Spot1
            Write-Host ===============================================================================
            Write-Host -ForegroundColor DarkRed "No Response: $_ is not responding or has very high latency. Skipping."
            #Write-Host Spot2
            Write-Host ===============================================================================
            Write-Output =============================================================================== | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            Write-Output "No Response: $_ did not respond or had very high latency. Skipped." | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            Write-Output =============================================================================== | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
        }
        else {
            $PingTest = Test-Connection -Count $using:ShortPingAmount -Ping -IPv4 -DontFragment -TargetName $_
            $PingTest | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            $IPFile = "$using:OutLocation\$_.txt"
            if ((($PingTest.Status) -match "TimedOut").count -gt 0) {
                #Write-Host Spot3
                Write-Host ===============================================================================
                Write-Host -ForegroundColor DarkRed Dropped: $PingTest.DisplayAddress.GetValue(0) dropped ((($PingTest.Status) -match "TimedOut").count/$using:ShortPingAmount).ToString("P") of packets
                "Dropped: " + $PingTest.DisplayAddress.GetValue(0) + " dropped " + ((($PingTest.Status) -match "TimedOut").count/$using:ShortPingAmount).ToString("P") + " of packets " | Out-File -FilePath $IPFile -Force -Append
            }
            elseif (!(((($PingTest.Latency) -ge $using:High).count/$using:ShortPingAmount) -gt 0)) {
                #Write-Host Spot4
                Write-Host ===============================================================================   
            }            
            if (((($PingTest.Latency) -ge $using:High).count/$using:ShortPingAmount) -gt 0) {
                Write-Host -ForegroundColor Red High Latency: $PingTest.DisplayAddress.GetValue(0) had ((($PingTest.Latency) -ge $using:High).count/$using:ShortPingAmount).ToString("P") of packets over $using:High ms
                $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:High).count/$using:ShortPingAmount).ToString("P") + " of packets over $using:High ms" | Out-File -FilePath $IPFile -Force -Append
                if (((($PingTest.Latency) -ge $using:Med).count/$using:ShortPingAmount) -gt 0) {
                    Write-Host -ForegroundColor Yellow "     "Medium Latency: $PingTest.DisplayAddress.GetValue(0) had ((($PingTest.Latency) -ge $using:Med).count/$using:ShortPingAmount).ToString("P") of packets over $using:Med ms
                    $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Med).count/$using:ShortPingAmount).ToString("P") + " of packets over $using:Med ms" | Out-File -FilePath $IPFile -Force -Append
                    if (((($PingTest.Latency) -ge $using:Low).count/$using:ShortPingAmount) -gt 0) {
                        Write-Host -ForegroundColor White "          "Low Latency: $PingTest.DisplayAddress.GetValue(0) had ((($PingTest.Latency) -ge $using:Low).count/$using:ShortPingAmount).ToString("P") of packets over $using:Low ms
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Low).count/$using:ShortPingAmount).ToString("P") + " of packets over $using:Low ms" | Out-File -FilePath $IPFile -Force -Append
                    }
                }
                #Write-Host Spot5
                Write-Host ===============================================================================
            }
            else {
                Write-Output "===============================================================================" | Out-File -FilePath $IPFile -Force -Append
                $PingTest.DisplayAddress.GetValue(0) + " had no latency based on defined thresholds" | Out-File -FilePath $IPFile -Force -Append
                Write-Output "===============================================================================" | Out-File -FilePath $IPFile -Force -Append
            }
        }
    }
}

if ($ShortOrLong -eq 2) {
    Write-Host "Running short ping test..."
    Write-Host ""
    Write-Host "Noticed issues:"
    Write-Host ""
    $IPList | ForEach-Object -ThrottleLimit 20 -Verbose -Parallel {
        $AliveTest = Test-Connection -Count 3 -Ping -IPv4 -DontFragment -TargetName $_
        $AliveTest | Out-File -FilePath $using:OutLocation\$_.txt
        if ($AliveTest.Status -notcontains "Success") {
            #Write-Host Spot1
            Write-Host ===============================================================================
            Write-Host -ForegroundColor DarkRed "No Response: $_ is not responding or has very high latency. Skipping."
            #Write-Host Spot2
            Write-Host ===============================================================================
            Write-Output =============================================================================== | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            Write-Output "No Response: $_ did not respond or had very high latency. Skipped." | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            Write-Output =============================================================================== | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
        }
        else {
            $PingTest = Test-Connection -Count $using:LongPingAmount -Ping -IPv4 -DontFragment -TargetName $_
            $PingTest | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            $IPFile = "$using:OutLocation\$_.txt"
            if ((($PingTest.Status) -match "TimedOut").count -gt 0) {
                #Write-Host Spot3
                Write-Host ===============================================================================
                Write-Host -ForegroundColor DarkRed Dropped: $PingTest.DisplayAddress.GetValue(0) dropped ((($PingTest.Status) -match "TimedOut").count/$using:LongPingAmount).ToString("P") of packets
                "Dropped: " + $PingTest.DisplayAddress.GetValue(0) + " dropped " + ((($PingTest.Status) -match "TimedOut").count/$using:ShortPingAmount).ToString("P") + " of packets " | Out-File -FilePath $IPFile -Force -Append
            }
            elseif (((($PingTest.Latency) -ge $using:High).count/$using:LongPingAmount) -gt 0) {
                #Write-Host Spot4
                Write-Host ===============================================================================   
            }            
            if (((($PingTest.Latency) -ge $using:High).count/$using:LongPingAmount) -gt 0) {
                Write-Host -ForegroundColor Red High Latency: $PingTest.DisplayAddress.GetValue(0) had ((($PingTest.Latency) -ge $using:High).count/$using:LongPingAmount).ToString("P") of packets over $using:High ms
                $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:High).count/$using:LongPingAmount).ToString("P") + " of packets over $using:High ms" | Out-File -FilePath $IPFile -Force -Append
                if (((($PingTest.Latency) -ge $using:Med).count/$using:LongPingAmount) -gt 0) {
                    Write-Host -ForegroundColor Yellow "     "Medium Latency: $PingTest.DisplayAddress.GetValue(0) had ((($PingTest.Latency) -ge $using:Med).count/$using:LongPingAmount).ToString("P") of packets over $using:Med ms
                    $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Med).count/$using:LongPingAmount).ToString("P") + " of packets over $using:Med ms" | Out-File -FilePath $IPFile -Force -Append
                    if (((($PingTest.Latency) -ge $using:Low).count/$using:LongPingAmount) -gt 0) {
                        Write-Host -ForegroundColor White "          "Low Latency: $PingTest.DisplayAddress.GetValue(0) had ((($PingTest.Latency) -ge $using:Low).count/$using:LongPingAmount).ToString("P") of packets over $using:Low ms
                        $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:Low).count/$using:LongPingAmount).ToString("P") + " of packets over $using:Low ms" | Out-File -FilePath $IPFile -Force -Append
                    }
                }
                #Write-Host Spot5
                Write-Host ===============================================================================
            }
            else {
                Write-Output "===============================================================================" | Out-File -FilePath $IPFile -Force -Append
                $PingTest.DisplayAddress.GetValue(0) + " had no latency based on defined thresholds" | Out-File -FilePath $IPFile -Force -Append
                Write-Output "===============================================================================" | Out-File -FilePath $IPFile -Force -Append
            }
        }
    }
}

#Location and name of results
$Files = Get-ChildItem $OutLocation

#Write results to file (All results recorded)
$ResultTable = @{}
$ResultTable.IPs = @{}
foreach ($File in $Files) {
    $Content = Get-Content -Path $File.FullName
    $FileName = $File.BaseName
    $ResultTable.IPs."$FileName" = @{}
    $ResultTable.IPs."$FileName".Dead = @()
    $ResultTable.IPs."$FileName".High = @()
    $ResultTable.IPs."$FileName".Medium = @()
    $ResultTable.IPs."$FileName".Low = @()
    if ("$Content" -match 'TimedOut') {
        if ("$Content" -match 'is not responding or has high latency') {
            Write-Output "Dead: $FileName" | Out-file -Path $Results -Force -Append
            $ResultTable.IPs."$FileName".Dead = $true
        }
        else {
            Write-Output "Dropped :$FileName" | Out-file -Path $Results -Force -Append
            $ResultTable.IPs."$FileName".Dead = $false
        }
    }
    if ("$Content" -match "over $Low") {
        if (!("$Content" -notmatch "over $Med")) {
            if ("$Content" -match "over $Med") {
                if (!("$Content" -notmatch "over $High")) {
                    if ("$Content" -match "over $High") {
                        $ResultTable.IPs."$FileName".High = $true
                        Write-Output "High Latency: $FileName" | Out-File -Path $Results -Force -Append
                    }
                    else {
                        $ResultTable.IPs."$FileName".High = $false
                    }
                }
            }
            else {
                $ResultTable.IPs."$FileName".Medium = $false
                Write-Output "Medium Latency: $FileName" | Out-File -Path $Results -Force -Append
            }
        }
    }
    else {
        $ResultTable.IPs.$FileName.Low = $false
        Write-Output "OK: $FileName" | Out-File -Path $Results -Force -Append
    }
}
$ResultTable.Message | Sort-Object
Write-Host ""
Write-Host "All results recorded to $OutLocation\Results.txt."
Write-Host ""
