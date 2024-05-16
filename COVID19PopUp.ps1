# Script that makes a popup to be ack'd for confirmation of symptoms. Text file in appdata so it detects on a per user basis rather than whole computer.
# Add Framework/Variables
Add-Type -AssemblyName System.Windows.Forms
Set-ExecutionPolicy Unrestricted
[DateTime] $lastRun = Get-Date -Date (Get-Date).Date
$Folder = ($env:USERPROFILE + "\appdata\local\CovidScript")
$FolderExist = Test-Path $Folder
$File = ($env:USERPROFILE + "\appdata\local\CovidScript\COVIDSurvey.txt")

# Check for existence of Kaseya appdata folder. Make folder if it does not exist.
If ($FolderExist -eq $false) {
    mkdir ($env:USERPROFILE + "\appdata\local\CovidScript")
}

# If $file exists $runonce is equal to whatever content is inside the file, else $runonce equals 0.
If (Test-Path $File) {
    $FileContent = Get-ChildItem ($File) | Where-Object {$_.LastWriteTime.Date -ge $lastRun}
    If ($null -eq $FileContent) {
        $RunOnce = 0
    }
    Else {
        $RunOnce = Get-Content $FileContent
    }
}
Else {
    $RunOnce = 0
}

# If $runonce is equal to 0 show the popup.
If ($RunOnce -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("Before you begin your workday please review the following:

Within the past 2 weeks have you had any of the following:

1.	Fever (100.4° or higher) or feeling feverish
2.	A Persistent New Cough
3.	Chills, Shakes, Headache and/or Unusual Muscle Aches
4.	Shortness of Breath (not severe)
5.	New loss of taste and/or smell
6.	Been exposed to anyone confirmed with COVID-19
7.	Traveled outside of the State of X and/or any known high risk areas within X.

If you answered yes to any of the above question you must contact your direct manager or leader before you begin your work day.

Please click ‘OK’ below indicating your understanding and acceptance of this self-assessment." , "COVID-19 Employee Self-Assessment" ,[System.Windows.Forms.MessageBoxButtons]::OK
)

# Convert $runonce to an interger as a new variable since there are times when adding to it caused problems as a string. Output value to $File. 
    $runOnceint = [int]$runOnce
    $runOnceint++
    $runOnceint | Out-File ($File) -Force
}
