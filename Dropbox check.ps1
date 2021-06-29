#Checks program files and appdata for dropbox client. Designed for an external app to react to the info the script reocrds.

$OutLocation = #Location
$usersfolder = get-childitem C:\users

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
