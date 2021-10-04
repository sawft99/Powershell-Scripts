#MADE FOR PS7!
#Pings in parallel. Reports to a text file and to console.
#$CSV is meant to have a field labeled "IP_Address". This can be changed as needed.

Clear-Host

#Variables
$OutLocation = #"C:\Location"
$Results = "$OutLocation\Results.txt"
$CSV = #"C:\CSVFile.csv"
#Note Variables represent thresholds in milliseconds. Reporting will display anything over the values. For example 
#MinLatency = 50, will report x% of packets over 50 ms
#MedLatency = 30, will  report x% of packets over 30 ms
#IdealLatency = 20, will  report x% of packets over 20 ms
#Reporting in the console will create a tabed cascading list to show how much of each condition was met from highest threshold to lowest.
$MinLatency = 60
$MedLatency = 50
$IdealLatency = 30

#Create PSobject with ips parsed from CSV
$IPListCSV = Import-Csv $CSV | ForEach-Object {[PSCustomObject]@{
    'IPaddress' = $_.IP_Address}
}

#Shorten IPListCSV Object
$IPList = $IPListCSV.IPAddress

#Parallel ping. Results recorded to each appropriate file
Write-Host ""
do {
    $PingAmountAsk = Read-Host -Prompt "Enter number of pings to send as a test for each connection"
    $PingAmount = [int]$PingAmountAsk
    Clear-Host
    if ($PingAmount.GetType().Name -ne "Int32") {
        Write-Host Please enter a valid number.
        Write-Host ""
    }
} while ($PingAmount.GetType().Name -ne "Int32")
Clear-Host
Write-Host "Running Ping Test..."
Write-Host ""
Write-Host "Noticed Issues:"
Write-Host ""
$IPList | ForEach-Object -ThrottleLimit 10 -Verbose -Parallel {
    $AliveTest = Test-Connection -Count 3 -Ping -IPv4 -DontFragment -TargetName $_
    $IPFile = "$using:OutLocation\$_.txt"
    $AliveTest | Out-File -FilePath $IPFile
    if ($AliveTest.Status -notcontains "Success") {
        Write-Host ===============================================================================
        Write-Host -ForegroundColor DarkRed "Dead: $_ is not responding or has very high latency. Skipping."
        Write-Output =============================================================================== | Out-File -FilePath $IPFile -Force -Append
        Write-Output "Dead: $_ is not responding or has very high latency. Skipping." | Out-File -FilePath $IPFile -Force -Append
        Write-Output =============================================================================== | Out-File -FilePath $IPFile -Force -Append
    }
    else {
        $PingTest = Test-Connection -Count $using:PingAmount -Ping -IPv4 -DontFragment -TargetName $_
        $HighTest = (($PingTest.Latency) -gt $using:MinLatency).count/$using:PingAmount -gt 0 -and (($PingTest.Latency -gt $using:MedLatency).count/$using:PingAmount -gt 0)
        $MedTest = (($PingTest.Latency) -gt $using:MedLatency).count/$using:PingAmount -gt 0 -and (($PingTest.Latency -gt $using:IdealLatency).count/$using:PingAmount -gt 0)
        $LowTest = (($PingTest.Latency) -gt $using:IdealLatency).count/$using:PingAmount -gt 0
        $PingTest | Out-File -FilePath $IPFile -Force -Append
        if ((($PingTest.Status) -match "TimedOut").count -gt 0 -or ((($PingTest.Latency) -gt $using:IdealLatency).count/$using:PingAmount) -gt 0) {
            Write-Host ===============================================================================
            "===============================================================================" | Out-File $IPFile -Force -Append
            if ((($PingTest.Status) -match "TimedOut").count -gt 0) {
                Write-Host -ForegroundColor DarkRed Dropped: $PingTest.DisplayAddress.GetValue(0) dropped ((($PingTest.Status) -match "TimedOut").count/$using:PingAmount).ToString("P") of packets
                "Dropped: " + $PingTest.DisplayAddress.GetValue(0) + " dropped " + ((($PingTest.Status) -match "TimedOut").count/$using:PingAmount).ToString("P") + " of packets " | Out-File -FilePath $IPFile -Force -Append
            }
        }  
        if ($HighTest) {
            Write-Host -ForegroundColor Red High Latency: $PingTest.DisplayAddress.GetValue(0) had ((($PingTest.Latency) -ge $using:MinLatency).count/$using:PingAmount).ToString("P") of packets over $using:MinLatency ms
            "High Latency: " + $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:MinLatency).count/$using:PingAmount).ToString("P") +  " of packets over " + $using:MinLatency + " ms" | Out-File -FilePath $IPFile -Force -Append
        } 
        if ($MedTest) {
            Write-Host -ForegroundColor Yellow Medium Latency: $PingTest.DisplayAddress.GetValue(0) had ((($PingTest.Latency) -ge $using:MedLatency).count/$using:PingAmount).ToString("P") of packets over $using:MedLatency ms | Out-File -FilePath $IPFile -Force -Append
            "Medium Latency: " + $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:MedLatency).count/$using:PingAmount).ToString("P") + " of packets over " + $using:MedLatency + " ms" | Out-File -FilePath $IPFile -Force -Append
        }
        if ($LowTest) {
            Write-Host -ForegroundColor White Low Latency: $PingTest.DisplayAddress.GetValue(0) had ((($PingTest.Latency) -ge $using:IdealLatency).count/$using:PingAmount).ToString("P") of packets over $using:IdealLatency ms | Out-File -FilePath $IPFile -Force -Append
            "Low Latency: " + $PingTest.DisplayAddress.GetValue(0) + " had " + ((($PingTest.Latency) -ge $using:IdealLatency).count/$using:PingAmount).ToString("P") + " of packets over " + $using:IdealLatency + "ms" | Out-File -FilePath $IPFile -Force -Append
        }
        else {
            if (($PingTest.Status) -notmatch "TimedOut") {
            "===============================================================================" | Out-File -FilePath $IPFile -Force -Append
            $PingTest.DisplayAddress.GetValue(0) + " had no latency based on defined thresholds" | Out-File -FilePath $IPFile -Force -Append
            "===============================================================================" | Out-File -FilePath $IPFile -Force -Append
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
    $ResultTable.IPs."$FileName" = @()
    if ("$Content" -match 'TimedOut') {
        if ("$Content" -match 'is not responding or has very high latency') {
            $ResultTable.IPs."$FileName" = "Dead"
        }
        else {
            $ResultTable.IPs."$FileName" = "Dropped"
        }
    }
    elseif ("$Content" -match "over $IdealLatency") {
        $ResultTable.IPs."$FileName" = "IdealLatency"
        if ("$Content" -match "over $MedLatency") {
            $ResultTable.IPs."$FileName" = "MedLatency"
            if ("$Content" -match "over $MinLatency") {
                $ResultTable.IPs."$FileName" = "HighLatency"
                    }
            else {
                $ResultTable.IPs."$FileName" = "MedLatency"
            }
        }
        else {
            $ResultTable.IPs."$FileName" = "LowLatency"
        }
    }
    elseif ("$Content" -notmatch "Dropped: $FileName" -and "$Content" -notmatch "over $IdealLatency") {
        $ResultTable.IPs."$FileName" = "OK"
    }
}

$ResultTable.IPs.GetEnumerator() | Sort-Object -Property Value
$ResultTable.IPs.GetEnumerator() | Sort-Object -Property Value | Select-Object -Property Key,Value | Export-Csv -NoTypeInformation $Results

Write-Host ""
Write-Host "All results recorded to $Results"
Write-Host ""
