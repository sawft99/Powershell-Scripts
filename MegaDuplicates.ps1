#Find duplicate files likely made from sync app on phones
#Looks for files ending in '_1'
#May not work properly if the '_1.' pattern repeats anywhere else in a file name
#Uncomment whichever delete line(s) you want at the end to remove originals/duplicates

#Folder to look through
$Folder = 'C:\PathToMegaPhonePicFolder'

#Get list of files with '_1.' and skip directories
$Files = Get-ChildItem -Path $Folder | Where-Object -Property Mode -EQ "-a----"
$Duplicates = $Files | Where-Object -Property FullName -Match '_1\.'

#Premade arrays
$Originals = @()
$NonDup = @()

#Check that there is a version of a file not ending in '_1'
ForEach ($DupFile in $Duplicates) {
    $End = ('_1' + $DupFile.Extension)
    $TrimDup = $DupFile.FullName -split "$End"
    $Original = $TrimDup[0] + $DupFile.Extension
    #Since an original file without '_1' is assumed, check for existence and then add it to the $Originals variable if it exists
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
$Duplicates = $Duplicates.FullName
$NonDup = $NonDup.FullName

Write-Host ""
Write-Host ============================================
Write-Host Duplicate files without a matching original
Write-Host ============================================
Write-Host ""
$NonDup

#Final duplicate file list
#Duplicate files that don't have a matching original file without "_1" at the end are removed
#Since that would mean there is no duplicate to an original
$DupFinal = $Duplicates.GetEnumerator() | Where-Object -FilterScript {!($_ -in $NonDup)}

#Delete originals and/or duplicates
#Uncomment whichever delete line you want
Write-Host ""
Write-Host ========================
Write-Host Duplicates to be deleted
Write-Host ========================
Write-Host ""
$DupFinal
#Remove-Item $Dupfinal

Write-Host ""
Write-Host =======================
Write-Host Originals to be deleted
Write-Host =======================
Write-Host ""
$Originals
#Remove-Item $Originals
