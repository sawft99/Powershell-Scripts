#Checks program files and appdata for dropbox client.

$OutLocation = #Location
$usersfolder = get-childitem C:\Users

foreach ($user in $usersfolder) {
    if (Test-Path C:\Users\$user\appdata\roaming\Dropbox\bin\Dropbox.exe) {
        $results = "Exists"
        $results | Out-File $OutLocation\dropboxdetect.txt
    }
}

if (Test-Path "C:\Program Files (x86)\Dropbox\Client\Dropbox.exe") {
    $results = "Exists"
    $results | Out-File $OutLocation\dropboxdetect.txt
}
    
if ($null -eq $results) {
    $results = "None"
    $results | Out-File $OutLocation\dropboxdetect.txt
}
