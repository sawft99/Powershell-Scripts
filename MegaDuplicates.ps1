#Find duplicate files likely made from sync app on phones
#Looks for files ending in '_1.', '_2.', or '_3'
#Uncomment whichever delete line(s) you want at the end to remove originals/duplicates
Clear-Host

#Variables
$Folder = 'C:\PathToMegaPhonePicFolder'
$Originals = @()
$NonDup = @()
$RemovedFiles = @()
$SkippedFiles = @()
$Date = Get-Date
#For delete function at end if you want to delete files newer than X days otherwise a high threshold is default
$NewerThanXDays = 9999999999

#Get list of files with endings and skip directories
$Files = Get-ChildItem -Path $Folder -Recurse | Where-Object -Property Mode -EQ "-a----"
$Duplicates = $Files | Where-Object {($_.FullName -Match '_1\.') -or ($_.FullName -Match '_2\.') -or ($_.FullName -Match '_3\.')}

#Check that there is a version of a file not ending in '_1', '_2', '_3'
ForEach ($DupFile in $Duplicates) {
    [int]$TestResult = 0
    $TrimDup = $DupFile.FullName
    if (($TrimDup | Where-Object {($_ -Match '_1\.')}).Count -eq 1) {
        $TestResult++
        $End = ('_1' + $DupFile.Extension)
    }
    if (($TrimDup | Where-Object {($_ -Match '_2\.')}).Count -eq 1) {
        $TestResult++
        $End = ('_2' + $DupFile.Extension)
    }
    if (($TrimDup | Where-Object {($_ -Match '_3\.')}).Count -eq 1) {
        $TestResult++
        $End = ('_3' + $DupFile.Extension)
    }
    if ($TestResult -ne 1) {
        Write-Host -ForegroundColor Red "Issue with $TrimDup. Manually resolve."
    }
    $TrimDup = $DupFile.FullName -split "$End"
    $Original = $TrimDup[0] + $DupFile.Extension
    #Since an original file without '_1/2/3' is assumed, check for existence and then add it to the $Originals variable if it exists
    #Else add the file to $NonDup variable to later remove from the $Duplicates variable
    if (Test-Path $Original) {
        $Originals += $Original
    } else {
        $NonDup += $DupFile
    }
    Remove-Variable End
    Remove-Variable TrimDup
    Remove-Variable Original
}

#Shorten to just path
$Duplicates = $Duplicates.FullName | Sort-Object
$NonDup = $NonDup.FullName | Sort-Object

#Final duplicate file list
#Duplicate files that don't have a matching original file without "_1" at the end are removed
#Since that would mean there is no original file
$DupFinal = $Duplicates.GetEnumerator() | Where-Object -FilterScript {!($_ -in $NonDup)}

#Optional function to delete files newer than X days
function DeleteNewerFiles {
    param (
        [Parameter(Mandatory=$true)]$FilePath,
        [Parameter(Mandatory=$true)]$LessThanDays
    )
    ForEach ($File in $FilePath) {
        if (Test-Path $File) {
            $FileTime = (Get-ChildItem $File).CreationTime
            $TimeDiff = $Date - $FileTime
            $TimeDiff = $TimeDiff.Days
            if ($TimeDiff -lt $NewerThanXDays) {
                Remove-Item $File
                $global:RemovedFiles += $File
            } else {
                $global:SkippedFiles += $File
            }
            Remove-Variable FileTime
            Remove-Variable TimeDiff
        } else {Continue}
    }
}
#Files with no matching original name
Write-Host ""
Write-Host =================================
Write-Host Files without a matching original
Write-Host =================================
Write-Host ""
$NonDup

#Duplicates
Write-Host ""
Write-Host ===============
Write-Host Duplicate files
Write-Host ===============
Write-Host ""
$DupFinal

#Originals
Write-Host ""
Write-Host ==============
Write-Host Original files
Write-Host ==============
Write-Host ""
$Originals

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!Uncomment either DeleteNewerFiles lines to delete duplicate files, original files, or both!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#DeleteNewerFiles $Originals $NewerThanXDays
Write-Host ""
Write-Host =============
Write-Host Deleted files
Write-Host =============
Write-Host ""
If ($RemovedFiles.Count -gt 0) {
    $RemovedFiles | Sort-Object
} else {
    Write-Host "Nothing deleted"
}

#Files skipped for being older than X days
DeleteNewerFiles $DupFinal $NewerThanXDays
Write-Host ""
Write-Host =============
Write-Host Skipped files
Write-Host =============
Write-Host ""
If ($SkippedFiles.Count -gt 0) {
    $SkippedFiles | Sort-Object
} else {
    Write-Host "Nothing skipped"
}
