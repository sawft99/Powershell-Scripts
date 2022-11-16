#About
#---
#Find duplicate files likely made from Mega sync app on phones
#Looks for files ending in '_1.', '_2.', or '_3'
#This script can potentially delete a lot of files on your PC and in the cloud so I have a bit of a long winded documentation below in order for you to fully understand how it works
#---
#Reason
#---
#I began running into this issue by using tools that remove metadata both on my phone and PC
#I have Mega set to preserve the original files names on my phone
#However once the phone of course detects there is a difference in its copy versus the cloud it will reupload and append _x at the end of the original file name
#I end up with a number of File_1.jpg,File_2.jpg, etc. copies
#---
#My Method
#---
#  1. Run this script as default with both 'DeleteChoice' variables set to $True along with the $DryRun variable as well
#    - I do both because I usually keep everything on my phone so once everything is sorted out the 'right one' will reupload from my phone
#    - By doing both you will also get a full idea of how the script handles the files. It's just more information for you
#    - A more common situation is people deleting local copies on their phone after it is uploaded to the cloud
#    - Therefore you more than likely want to delete only originals or only duplicates. Otherwise you would end up with 0 copies if left in the default state
#    - Adjust the 'DeleteChoice' variables for your purposes. I'd recommend changing AFTER doing all your rounds with the $DryRun
#    - Hopefully, either all of the originals or all of the duplicates found represent the final files you're looking to keep
#    - Otherwise a mix will be time consuming depending on how many files you have and how mixed the results are
#    - Even if you limit or disable deletions all together the $DryRun feature should act as a good reporting tool if nothing else
#  2. Review problem files (multiple filter matches) and what will be skipped, deleted, etc.
#  3. Note the operations that will be performed from the hypothetical $DryRun output
#  4. If the script will handle the files in a way you don't like, changing the 'DeleteChoice' and $NewerThanXDays variables will probably take care of the most common situations
#    - If it still does not handle some files to your liking then you may need to manually resolve it yourself
#  5. When comfortable with the hypothetical output, change one or both 'DeleteChoice' variables so you only delete originals, duplicates, or both
#    - Changing the $NewerThanXdays variable is optional. This feature could help by narrowing your scope to something like the last few days if it only recently became an issue. Thus less files to worry about
#  6. Set $DryRun to $False and rerun the script so that the operations will actually occur now
#  7. Optionally rename things on your phone to remove '_1/2/3' at the end and/or delete the duplicates on your phone
#    - Unless you somehow had a file in the future that matched the name of your duplicate file, meaning it ends in '_1/2/3', then you shouldn't need to worry about the same files being removed again in the future
#  8. Allow phone to reupload
#  9. Repeat as needed
Clear-Host

#Variables
$Folder = 'C:\PathToMegaPicFolder'
#Set '$DryRun' to '$True' in order to simulate actions. Set to '$False' to perform the actual operations
$DryRun = $True
#Set 'Delete' variables to '$True' to remove that file type otherwise '$False' will skip them
$DeleteOriginalChoice = $False
$DeleteDuplicateChoice = $True
#For delete function at the end if you only want to worry about files created within X days. Otherwise a high threshold is default so as to capture all duplicates found
$NewerThanXDays = 9999999999
#Premade arrays and other variables. You shouldn't need to mess with these
$Originals = @()
$DupFinal = @()
$NonDup = @()
$RemovedFiles = @()
$SkippedFiles = @()
$ProblemFiles = @()
$Date = Get-Date

#Check for $DryRun, and $Delete values to save you from yourself
if (($DryRun -ne $True) -and ($DryRun -ne $False)) {
    Write-Host -ForegroundColor Red '$DryRun' value needs to be either '$True' or '$False'
    Exit
}
if (($DeleteOriginalChoice -ne $True) -and ($DeleteOriginalChoice-ne $False)) {
    Write-Host -ForegroundColor Red '$DeleteOriginalChoice' value needs to be either '$True' or '$False'
    Exit
}
if (($DeleteDuplicateChoice -ne $True) -and ($DeleteDuplicateChoice-ne $False)) {
    Write-Host -ForegroundColor Red '$DeleteDuplicateChoice' value needs to be either '$True' or '$False'
    Exit
}

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
        $ProblemFiles += $DupFile
    } else {
        $TrimDup = $DupFile.FullName -split "$End"
        $Original = $TrimDup[0] + $DupFile.Extension
        #Since an original file without '_1/2/3' is assumed, check for existence and then add it to the $Originals variable if it exists
        #Else add the file to $NonDup variable to note files with a duplicate style name but no matching original
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
$ProblemFiles = $ProblemFiles.FullName | Sort-Object
$Duplicates = $Duplicates.FullName | Sort-Object
$NonDup = $NonDup.FullName | Sort-Object

#Final duplicate file list
#Duplicate files that don't have a matching original file without '_1/2/3' at the end are not removed
#Since that would mean there is no original file
$DupFinal = $DupFinal.GetEnumerator() | Where-Object -FilterScript {!($_ -in $NonDup)}
$DupFinal = $DupFinal.FullName

#Function to delete files $NewerThanXDays
function DeleteFiles {
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
                if ($DryRun -eq $False) {
                    Remove-Item $File
                }
                $global:RemovedFiles += $File
            } else {
                $global:SkippedFiles += $File
            }
            Remove-Variable FileTime
            Remove-Variable TimeDiff
        } else {Continue}
    }
}

#Problem files that match more than 1 thing in the filters
Write-Host ""
Write-Host ===============
Write-Host Problem files
Write-Host ===============
Write-Host ""
if ($ProblemFiles.Count -gt 0) {
    $ProblemFiles
    Write-Host ""
    Write-Host -ForegroundColor Red '$ProblemFiles are a result of files that match the filters in more than one spot
Out of caution no additional operations, such as deletions, are performed on them
You will need to manually resolve these issues by either renaming the file or deleting them yourself
Example: Test_1_2._3.txt'
} else {
    Write-Host No problem files found
}

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!The default for file deletions is to remove both duplicate and original files       !!
#!!Change 'DeleteChoice' variables at top of script to change this behavior            !!
#!!You can also do a $DryRun to see what will happen without actually deleting anything!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


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

#Original files
Write-Host ""
Write-Host ==============
Write-Host Original files
Write-Host ==============
Write-Host ""
if ($Originals.Count -gt 0) {
    $Originals
} else {
    Write-Host No original files to a matching duplicate found
}

#Original files being deleted
if ($DupFinal.Count -gt 0) {
    if ($DeleteDuplicateChoice -eq $True) {
        DeleteFiles $DupFinal $NewerThanXDays
    }
}
if ($Originals.Count -gt 0) {
    if ($DeleteOriginalChoice -eq $True) {
        DeleteFiles $Originals $NewerThanXDays
    }
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
if ($DryRun -eq $True) {
    Write-Host -ForegroundColor Cyan This was only a simulation. Change the value of '$DryRun' to '$False' to actually perform the operations.
    Write-Host ""
}
