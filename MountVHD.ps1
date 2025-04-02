#Mounts VHD. Create a scheduled task with admin permissions to run at a given time such as logon.

[System.IO.DirectoryInfo]$VHDSourceFolder = 'C:\Directory'
$VHDS = Get-ChildItem $VHDSourceFolder | Where-Object {($_.Extension.EndsWith('.vhd')) -or ($_.Extension.EndsWith('.vhdx'))} | Sort-Object -Property FullName
#Possible drive letters to use
$DriveLetters = @('E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')

#---------

Clear-Host

Write-Host '
=========
VHD Mount
=========
'

if ($null -ne $Error.length) {Write-Host -ForegroundColor Red 'Error encountered' ; $LASTEXITCODE = 1 ; exit $LASTEXITCODE}

#Checkif any VHDs exist in folder if not, exit
if ($VHDS.Count -lt 1) {
    Write-Host -ForegroundColor Red 'No VHDs found
    '
    $LASTEXITCODE = 1
    exit $LASTEXITCODE
}

function CheckCurrentDrives {
    $CurrentMountedDrives = Get-Volume
    $CurrentMountedDrives | Sort-Object -Property DriveLetter
}
function CheckAvailableDriveLetters {
    $CurrentDrives = CheckCurrentDrives
    $AvailableDriveLetters = $DriveLetters | Where-Object {$_ -notin $CurrentDrives.DriveLetter}
    $AvailableDriveLetters
}
#Function to check for current mounts
function CheckCurrentDisks {
    $CurrentMountedDisks = Get-Disk | Where-Object {($_.FriendlyName.EndsWith('.vhd')) -or ($_.FriendlyName.EndsWith('.vhdx') -or ($_.Model -match 'Virtual Disk'))} | Select-Object -Property DiskNumber,PartitionStyle,OperationalStatus,HealthStatus,Size,FriendlyName,Location,Model
    $CurrentMountedDisks | Sort-Object -Property Location
}

#Check current mounted disks
$CurrentMountedDisks = CheckCurrentDisks

#Create list of VHDs to skip since they are already mounted
$SkipMountVHD = $VHDS | Where-Object -Property FullName -in $CurrentMountedDisks.Location
#Create list of VHDs not mounted
$DoMountVHD = $VHDS | Where-Object -Property FullName -notin $CurrentMountedDisks.Location

#Report what is being skipped since it is already mounted
foreach ($SkipVHD in $SkipMountVHD) {
    Write-Host -ForegroundColor Yellow "Already mounted, skipping: $($SkipVHD.FullName)"
    Remove-Variable SkipVHD
}

#Mount disks and assign drive letters in order of availability
foreach ($DoVHD in $DoMountVHD) {
    if ($null -ne $Error.length) {Write-Host -ForegroundColor Red 'Error encountered' ; $LASTEXITCODE = 1 ; exit $LASTEXITCODE}
    Write-Host "Mounting: $($DoVHD.FullName)"
    Mount-DiskImage $DoVHD.FullName | Out-Null
    $CurrentMountedDisks = CheckCurrentDisks
    $CurrentMountedDrives = CheckCurrentDrives
    $DiskNumber = ($CurrentMountedDisks | Where-Object -Property Location -eq $DoVHD.FullName).DiskNumber
    $Partitions = Get-Partition -DiskNumber $DiskNumber
    if ($null -ne $Error.length) {Write-Host -ForegroundColor Red 'Error encountered' ; $LASTEXITCODE = 1 ; exit $LASTEXITCODE}
    foreach ($Partition in $Partitions) {
        $AvailableDriveLetters = CheckAvailableDriveLetters
        $SelectedDriveLetter = $AvailableDriveLetters[0]
        Write-Host "Assigning $SelectedDriveLetter to partition" 
        Set-Partition $Partition.DiskNumber -PartitionNumber $Partition.PartitionNumber -NewDriveLetter $SelectedDriveLetter
        Remove-Variable AvailableDriveLetters,SelectedDriveLetter
        if ($null -ne $Error.length) {Write-Host -ForegroundColor Red 'Error encountered' ; $LASTEXITCODE = 1 ; exit $LASTEXITCODE}
    }
    Remove-Variable DoVHD,CurrentMountedDisks,CurrentMountedDrives,DiskNumber,Partition,Partitions
    if ($null -ne $Error.length) {Write-Host -ForegroundColor Red 'Error encountered' ; $LASTEXITCODE = 1 ; exit $LASTEXITCODE}
}

Write-Host ''

if ($null -eq $Error.length) {
    Write-Host -ForegroundColor Green 'All drives mounted with no errors'
    $LASTEXITCODE = 0
    exit $LASTEXITCODE
} else {
    Write-Host -ForegroundColor Red 'Errors encountered while mounting drives'
    $LASTEXITCODE = 1
    exit $LASTEXITCODE
}
