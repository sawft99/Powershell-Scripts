#Find duplicate files likely made from Mega sync app on phones
#Looks for files ending in '_1.', '_2.', or '_3'
#Uncomment whichever delete line(s) you want at the end to remove originals/duplicates
#  - The lines with the function named 'DeleteNewerFiles'
#My Method
#  1. Run this script and only uncomment the line to delete duplicates
#  2. Allow phone to reupload what it has
#  3. Rerun the script and have both duplicate and original delete lines uncommented
#    - Only originals that have a matching duplicate name (_1/2/3) will be removed
#    - This way you know you're only deleting originals that came from a duplicate file. Unless you had a file beforehand that may have matched the filter for some reason
#    - The script SHOULD alert you to this though
#  4. Optionally rename things on your phone to remove '_1/2/3' at the end
#    - Unless you somehow had a file in the future that matched the name of your duplicate file, meaning it ends in '_1/2/3', then you shouldn't need to worry about your files being removed in the future
Clear-Host

#Variables
$Folder = 'C:\PathToMegaPhonePicFolder'
$Originals = @()
$DupFinal = @()
$NonDup = @()
$RemovedFiles = @()
$SkippedFiles = @()
$Date = Get-Date
#For delete function at end if you only want to delete files newer than X days otherwise a high threshold is default so as to capture all duplicates found
$NewerThanXDays = 9999999999

#Get list of files with duplicate type endings and skip directories
$Files = Get-ChildItem -Path $Folder -Recurse | Where-Object -Property Mode -EQ "-a----"
$Duplicates = $Files | Where-Object {($_.FullName -Match '_1\.') -or ($_.FullName -Match '_2\.') -or ($_.FullName -Match '_3\.')}

#Check that there is a version of a file not ending in '_1', '_2', '_3'
#This method would confirm that there is a matching original to the duplicate file
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
    } else {
        $TrimDup = $DupFile.FullName -split "$End"
        $Original = $TrimDup[0] + $DupFile.Extension
        #Since an original file without '_1/2/3' is assumed, check for existence and then add it to the $Originals variable if it exists
        #Else add the file to $NonDup variable to note files with a duplicate stlye name but no matching original
        #$NonDup files will be skipped for deletion to prevent accidentally deleting an original file with no duplicate
        if (Test-Path $Original) {
            $Originals += $Original
            $DupFinal += $DupFile
        } else {
            $NonDup += $DupFile
        }
    }
    if (!($Null -eq $End)) {
        Remove-Variable End
    }
    if (!($Null -eq $TrimDup)) {
        Remove-Variable Trimdup
    }
    if (!($Null -eq $Original)) {
        Remove-Variable Original
    }
}

#Shorten to just file path
$Duplicates = $Duplicates.FullName | Sort-Object
$NonDup = $NonDup.FullName | Sort-Object

#Final duplicate file list
#Duplicate files that don't have a matching original file without '_1/2/3' at the end are not removed
#Since that would mean there is no original file
$DupFinal = $DupFinal.GetEnumerator() | Where-Object -FilterScript {!($_ -in $NonDup)}
$DupFinal = $DupFinal.FullName

#Function to delete files $NewerThanXDays
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
            #If you would want a type of 'preview' for what will happen without actually deleting anything you can comment out the Remove-Item line below
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
#Files with no matching original name that were excluded form deletion
Write-Host ""
Write-Host =================================
Write-Host Files without a matching original
Write-Host =================================
Write-Host ""
if ($NonDup.Count -gt 0) {
    $NonDup
} else {
    Write-Host No duplicate files missing an original
}

#Duplicates
Write-Host ""
Write-Host ===============
Write-Host Duplicate files
Write-Host ===============
Write-Host ""
if ($DupFinal.Count -gt 0) {
    $DupFinal
} else {
    Write-Host No duplicate files found
}


#Originals
Write-Host ""
Write-Host ==============
Write-Host Original files
Write-Host ==============
Write-Host ""
if ($Originals.Count -gt 0) {
    $Orginals
} else {
    Write-Host No original files to a matching duplicate found
}

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!Uncomment either DeleteNewerFiles lines to delete duplicate files, original files, or both!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#Original files being deleted
if ($Originals.Count -gt 0) {
    #DeleteNewerFiles $Originals $NewerThanXDays
}

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
if ($DupFinal.Count -gt 0) {
    #DeleteNewerFiles $DupFinal $NewerThanXDays
}
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
Write-Host ""
