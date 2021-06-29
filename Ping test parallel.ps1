#MADE FOR PS7!
#Pings in parallel. Reports to a text file and to console.
#$CSV is meant to have a field labeled "IP_Address". This can be changed as needed.

#Variables
$OutLocation = #Locaiton
$Results = #$OutLocation\Results.txt
$CSV = #CSV File

#Create PSobject with ips parsed from CSV
$Custom1 = Import-Csv $CSV | ForEach-Object {[PSCustomObject]@{
    'IPaddres' = $_.IP_Address}
}

#Shorten Custom1 Object
$Custom2 = $Custom1.IPaddres

#Parallel ping. Results recorded to each appropriate file
$Custom2 | ForEach-Object  -ThrottleLimit 20 -Verbose -Parallel {
    ping -n 50 $_ | Out-File -FilePath $using:OutLocation\$_.txt -Force -Append
}

#Location and name of results
$Files = Get-ChildItem $OutLocation
#| Select-Object -Property FullName

#Write result to host/console (Reports issues only)
foreach ($File in $Files -replace "@{FullName=" -replace "}")
{$Content= Get-Content -Path $file
    $Filename = $File.TrimStart("$OutLocation").TrimEnd('.txt')
    if ($Content -match 'timed out') {Write-host "$Filename dropped packets"}}

#Write results to file (All results recorded)
foreach ($File in $Files -replace "@{FullName=" -replace "}")
{$Content = Get-Content -Path $File
    $Filename = $File.TrimStart("$OutLocation").TrimEnd('.txt')
    if ($Content -match 'timed out') {Write-Output "$Filename dropped packets" | Out-file -Force -Path $Results -Append}
    else {Write-Output "$Filename is ok" | Out-File -Force -Path $Results -Append}}
