#Prepend and append file names

#Folder to run script in
[System.IO.DirectoryInfo]$Folder = 'C:\Folder'

#Run prepend or append commands? $true or $false
$RunPrepend = $true
$RunAppend = $false
#Recurse through sub folders? $true of $false
$PrependRecurse = $true
$AppendRecurse = $true
#Pattern to search for in file names 
$PrePattern = "Pre-"
$PostPattern = "-Post"
#Pattern to prepend or append
$ToPrepend = "Pre-"
$ToAppend = "-Post"

Clear-Host

Function PrependRename {
if ($PrePattern.Length -gt 0) {
        if ($PrependRecurse -eq $true) {
            #Matchedfiles indicates files already matching the pattern whereas UnmatchedFiles don't match the pattern
            #UnmatchedFiles will be prepended or appended based on the settings
            $PrependMatchedFiles = Get-ChildItem $Folder -Recurse | Where-Object {$_.BaseName.Startswith("$PrePattern") -eq $true -and $_.Mode.Startswith("d") -eq $false}
            $PrependUnmatchedFiles = Get-ChildItem $Folder -Recurse | Where-Object {$_.BaseName.Startswith("$PrePattern") -eq $false -and $_.Mode.Startswith("d") -eq $false}
        } else {
            $PrependMatchedFiles = Get-ChildItem $Folder | Where-Object {$_.BaseName.Startswith("$PrePattern") -eq $true -and $_.Mode.Startswith("d") -eq $false}
            $PrependUnmatchedFiles = Get-ChildItem $Folder | Where-Object {$_.BaseName.Startswith("$PrePattern") -eq $false -and $_.Mode.Startswith("d") -eq $false}
        }
    }
    if ($PrependUnmatchedFiles.Count -eq 0) {
        Write-Host Nothing changed
    } else {
        $PrependUnmatchedFiles | ForEach-Object {
            $Base = $_.BaseName
            $Extension = $_.Extension
            Write-Host Changed $_.Name to ("$ToPrepend" + "$Base" + "$Extension")
            Rename-Item -Path $_.FullName -NewName ("$ToPrepend" + "$Base" + "$Extension")
        }
    }
}

Function AppendRename {
if ($PostPattern.Length -gt 0) {
        if ($AppendRecurse -eq $true) {
            #Matchedfiles indicates files already matching the pattern whereas UnmatchedFiles don't match the pattern
            #UnmatchedFiles will be prepended or appended based on the settings
            $AppendMatchedFiles = Get-ChildItem $Folder -Recurse | Where-Object {$_.BaseName.Endswith("$PostPattern") -eq $true -and $_.Mode.Startswith("d") -eq $false}
            $AppendUnmatchedFiles = Get-ChildItem $Folder -Recurse | Where-Object {$_.BaseName.Endswith("$PostPattern") -eq $false -and $_.Mode.Startswith("d") -eq $false}
        } else {
            $AppendMatchedFiles = Get-ChildItem $Folder | Where-Object {$_.BaseName.Endswith("$PostPattern") -eq $true -and $_.Mode.Startswith("d") -eq $false}
            $AppendUnmatchedFiles = Get-ChildItem $Folder | Where-Object {$_.BaseName.Endswith("$PostPattern") -eq $false -and $_.Mode.Startswith("d") -eq $false}
        }
    }
    if ($AppendUnmatchedFiles.Count -eq 0) {
        Write-Host Nothing changed
    } else {
        $AppendUnmatchedFiles | ForEach-Object {
            $Base = $_.BaseName
            $Extension = $_.Extension
            Write-Host Changed $_.Name to ("$Base" + "$ToAppend" + "$Extension")
            Rename-Item -Path $_.FullName -NewName ("$Base" + "$ToAppend" + "$Extension")
        }
    }
}

If ($PrePattern.Length -gt 0 -and $RunPrepend -eq $true) {
    Write-Host ===============
    Write-Host Files prepended
    Write-Host ===============
    Write-Host ""
    PrependRename
    Write-Host ""
}

If ($PostPattern.Length -gt 0 -and $RunAppend -eq $true) {
    Write-Host ===============
    Write-Host Files appended
    Write-Host ===============
    Write-Host ""
    AppendRename
    Write-Host ""
}
