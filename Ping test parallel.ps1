#MADE FOR PS7!
#Pings in parallel. Reports to a text file and to console.
#$CSV is meant to have a field labeled "IP_Address". This can be changed as needed.

#Variables
$OutLocation = #Locaiton
$Results = #$OutLocation\Results.txt
$CSV = #CSV File

#Create PSobject with ips parsed from CSV
$Custom1 = Import-Csv $CSV | ForEach-Object {[PSCustomObject]@{
    'IPaddress' = $_.IP_Address}
}

#Shorten Custom1 Object
$Custom2 = $Custom1.IPAddress

#Short or Long test
Write-Host "

Options:

1. Short test (50 pings)
2. Long test (250 pings)
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
    $Custom2 | ForEach-Object -ThrottleLimit 20 -Verbose -Parallel {
        $AliveTest = Test-Connection -Count 3 -Ping -IPv4 -DontFragment -TargetName $_
        $AliveTest | Out-File -FilePath $using:OutLocation\$_.txt
        if ($AliveTest.Status -notcontains "Success") {
            Write-Warning "$_ is not responding or has high latency. Skipping."
            Write-Output "$_ is not responding or has high latency. Skipping." | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
        }
        else {
            $PingTest = Test-Connection -Count 50 -Ping -IPv4 -DontFragment -TargetName $_
            $PingTest | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            if (((($AliveTest.Latency) -ge 20).count/50).ToString("P") -gt 0) {
                $PingTest.DisplayAddress.GetValue(0) + " had " + ((($AliveTest.Latency) -ge 20).count/50).ToString("P") + " of packets over 50 ms"
                $PingTest.DisplayAddress.GetValue(0) + " had " + ((($AliveTest.Latency) -ge 20).count/50).ToString("P") + " of packets over 50 ms" | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
            }
        }
    }
}

if ($ShortOrLong -eq 2) {
    Write-Host "Running long ping test..."
    Write-Host ""
    $Custom2 | ForEach-Object -ThrottleLimit 20 -Verbose -Parallel {
        $AliveTest = Test-Connection -Count 3 -Ping -IPv4 -DontFragment -TargetName $_
        $AliveTest | Out-File -FilePath $using:OutLocation\$_.txt
        if ($AliveTest.status -notcontains "Success") {
            Write-Warning "$_ is not responding or has high latency. Skipping."
            Write-Output "$_ is not responding or has high latency. Skipping." | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
        }
        else {
            Test-Connection -Count 250 -Ping -IPv4 -DontFragment -TargetName $_ | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
        }
    }
}

#Location and name of results
$Files = Get-ChildItem $OutLocation

#Write result to host/console (Reports issues only)
Write-Host ""
Write-Host "Final results:"
Write-Host ""
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
