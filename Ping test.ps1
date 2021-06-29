#Pings resources one at a time and writes to console.
#CSV file in $Array should only have a list of ips to parse.

$OutLocation = #Locaiton
$Array = Get-Content -Path #Location\Info.csv

foreach ($IP in $Array) {
    ping -n 100 $IP | Out-File -FilePath $OutLocation\$IP.txt -Force
}

$Files = Get-ChildItem $OutLocation | Select-Object -Property FullName

foreach ($File in $Files -replace "@{FullName=" -replace "}") {
    $content= Get-Content -Path $file
    if ($content -match 'timed out') {
        Write-host "$file dropped packets"
    }
    else {
        Write-Host "$file is ok"
    }
}