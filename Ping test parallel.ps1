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
        Write-Warning "Please pick a valid option"
    }
}
while ($ShortOrLong -notin 1..2)
Write-Host ""

#Parallel ping. Results recorded to each appropriate file
if ($ShortOrLong -eq 1) {
    Write-Host "Running short ping test..."
    $Custom2 | ForEach-Object -ThrottleLimit 20 -Verbose -Parallel {
        $AliveTest = Test-Connection -Count 3 -Ping -IPv4 -DontFragment -TargetName $_
        if ($AliveTest.status -notcontains "Success") {
            Write-Warning "Dead host at $_ or high latency. Skipping"
        }
        else {
            ping -n 50 $_ | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append    
        }
    }
}

if ($ShortOrLong -eq 2) {
    Write-Host "Running long ping test..."
    $Custom2 | ForEach-Object -ThrottleLimit 20 -Verbose -Parallel {
        $AliveTest = Test-Connection -Count 3 -Ping -IPv4 -DontFragment -TargetName $_
        if ($AliveTest.status -notcontains "Success") {
            Write-Warning "Dead host at $_ or high latency. Skipping"
        }
        else {
            ping -n 250 $_ | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
        }
    }
}

#Location and name of results
$Files = Get-ChildItem $OutLocation

#Write result to host/console (Reports issues only)
foreach ($File in $Files) {
    $Content = Get-Content -Path $File.FullName
    $Filename = $File.BaseName
    if ($Content -match 'timed out') {
        Write-host "$Filename dropped packets"
    }
}

#Write results to file (All results recorded)
foreach ($File in $Files) { 
    $Content = Get-Content -Path $File.FullName
    $Filename = $File.BaseName
    if ($Content -match 'timed out') {
        Write-Output "$Filename dropped packets" | Out-file -Force -Path $Results -Append
    }
    else {
        Write-Output "$Filename is ok" | Out-File -Force -Path $Results -Append
    }
}
