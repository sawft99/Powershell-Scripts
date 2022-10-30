#Create and/or verify a hash with Windows certutil
#Made because I didn't know 'Get-FileHash' existed

#Types of hashes
$HashTypes = "MD2","MD4","MD5","SHA1","SHA256","SHA384","SHA512"

Clear-Host
function AskRun {
    Write-Host ""
    Write-Host ""
    do { 
        $OpPick = Read-Host -Prompt "Available operations:

    1. Create
    2. Verify

Select operaiton by number"
        if ($OpPick -notin 1..2) {
            Clear-Host
            Write-Warning "Select options '1' or '2'"
            Write-Host ""
        }
    } until ($OpPick -in 1..2)
    Clear-Host
    return $OpPick
}

function AskFile {
    Write-Host ""
    Write-Host ""
    do {
        $FilePath = Read-Host -Prompt "Enter folder/file path" 
        if ($Null -eq $FilePath -or $FilePath.Length -eq 0) {
            Clear-Host
            Write-Warning "Path can not be blank"
            Write-Host ""
        }
        elseif (!(Test-Path $FilePath)) {
            Clear-Host
            Write-Warning "Folder/File does not exist"
            Write-Host ""
        }
    } until (($Null -ne $FilePath -and $FilePath.Length -gt 0) -and (Test-Path $FilePath))
    $FilePath = Get-ChildItem -Recurse $FilePath | Where-Object {$_.GetType().Name -eq "FileInfo"}
    #Attempted to have file list show as the root directory and all underylying files rather than entire path
    #Selected C:\Users\Bob\Folder1 to verify
    #C:\Users\Bob\Folder1\file1.exe             | Folder1\file1.exe
    #C:\Users\Bob\Folder1\file2.exe             | Folder1\file2.eze
    #C:\Users\Bob\Folder1\Folder2\file3.exe     | Folder1\Folder2\file3.exe
    #Write-Host $FilePath.DirectoryName[0]
    #$global:RootDirTrim = $FilePath.DirectoryName[0].TrimEnd($FilePath.Directory.Name[0]).TrimEnd('\')
    Clear-Host
    return $FilePath
}

function AskHash {
    Write-Host ""
    Write-Host ""
    do {
    $HashOp = Read-Host -Prompt "Available hash operations:
  
1. MD2
2. MD4
3. MD5
4. SHA1
5. SHA256
6. SHA384
7. SHA512
    
Select operation by number"
    if ($HashOp -notin 1..7) {
        Clear-Host
        Write-Warning "Select an operation between 1-7"
        Write-Host ""
    }
    } until ($HashOp -in 1..7)
    $HashOp = $HashTypes[$HashOp - 1]
    Clear-Host
    return $HashOp
}

function CreateTable {
    $HashCalcTable = @()
    $TableInsert = @()
    If ($Null -eq $File) {
        $File = $FilePath.FullName
    }
    #$RootDir = $File.Trim($RootDirTrim)
    #Write-Host Rootdirtrim is $RootDirTrim
    #Write-Host Rootdir is $RootDir
    #Write-Host "Creating hash for $File"
    New-Variable -Name CalcHash -Value ((certutil.exe -hashfile $File $HashOp).Get(1))
    $TableInsert = [PSCustomObject]@{
        File                  = $File
        ($HashOp + " Value")  = $CalcHash
    }
    Write-Host Created $HashOp hash ($TableInsert.($HashOp + " Value")) for ($TableInsert.File)
    $HashCalcTable = $HashCalcTable + $TableInsert
    return $HashCalcTable
}

function CreateHashFile {
    $HashOp = AskHash
    Write-Host ""
    Write-Host ""
    Write-Host "Creating hashes..."
    Write-Host ""
    $HashCalcTable = CreateTable
    return $HashCalcTable
}

#Option to compare single file to list of hashes?
function VerifyHashFile {
    $HashOp = AskHash
    Write-Host ""
    Write-Host ""
    do {
        $CompareHash = Read-Host -Prompt "Input hash value to verify"
        if ($Null -eq $CompareHash -or $CompareHash.Length -eq 0) {
            Clear-Host
            Write-Warning "Enter a hash value"
            Write-Host ""
        }
    } until (!($Null -eq $CompareHash -or $CompareHash.Length -eq 0)) 
    Clear-Host
    Write-Host ""
    Write-Host ""
    Write-Host "Creating hashes..."
    Write-Host ""
    $HashCalcTable = CreateTable
    $MatchTest     = $HashCalcTable.($HashOp + " Value").IndexOf("$CompareHash")
    if ($MatchTest -eq -1) {
        Add-Member -InputObject $HashCalcTable -MemberType NoteProperty -Name "Compared Hash" -Value $CompareHash
        Add-Member -InputObject $HashCalcTable -MemberType NoteProperty -Name "Match" -Value "No"
    }
    else {
        Add-Member -InputObject $HashCalcTable -MemberType NoteProperty -Name "Compared Hash" -Value $CompareHash
        Add-Member -InputObject $HashCalcTable -MemberType NoteProperty -Name "Match" -Value "Yes"
    }
    return $HashCalcTable
}

function CreateHashFolder {
    $HashOp = AskHash
    Write-Host ""
    Write-Host ""
    Write-Host "Creating hashes..."
    Write-Host ""
    $HashCalcTable = @()
    ForEach ($File in $FilePath.FullName) {
        $StartTable = CreateTable
        $HashCalcTable = $HashCalcTable + $StartTable
    }
    return $HashCalcTable
}

function VerifyHashFolder {
    $HashOp = AskHash
    Write-Host ""
    Write-Host ""
    do {
        $HashFileImport = Read-Host -Prompt "Enter path to file containing hashes"
        if (($Null -eq $HashFileImport) -or ($HashFileImport.Length -eq 0)) {
            Clear-Host
            Write-Warning "Path can not be blank"
            Write-Host ""
        }
        elseif (!(Test-Path $HashFileImport)) {
            Clear-Host
            Write-Warning "File does not exist"
            Write-Host ""
        }
    } until (($Null -ne $HashFileImport -and $HashFileImport.Length -gt 0) -and (Test-Path $HashFileImport))
    $HashFileImport = Get-Content $HashFileImport
    $HashCalcTable = @()
    Clear-Host
    Write-Host ""
    Write-Host ""
    Write-Host "Creating hashes..."
    Write-Host ""
    ForEach ($File in $FilePath.FullName) {
        $StartTable      = CreateTable
        $HashCalcTable   = $HashCalcTable + $StartTable
    }
    Write-Host ""
    $NoMatchTable = @()    
    ForEach ($CalcFile in $HashCalcTable) {
        $MatchTest = $CalcFile.($HashOp + " Value") -in $HashFileImport
        if ($MatchTest -eq $false) {
            $MatchFile = $CalcFile.File
            $NoMatchTableInsert = [PSCustomObject]@{
                File = $MatchFile
                ($HashOp + " Value") = $CalcFile.($HashOp + " Value")
                "Compared Hash" = "No Match"
                Match = "No"
            }
            $NoMatchTable = $NoMatchTable + $NoMatchTableInsert
        }
        $MatchTest = $Null
    }
    $MatchTable = @()
    ForEach ($ImportedHash in $HashFileImport) {
        $MatchTest = $HashCalcTable.($HashOp + " Value").IndexOf("$ImportedHash")
        $MatchTableInsert = @()
        if ($MatchTest -gt -1) {
        $MatchSet = $HashCalcTable.($HashOp + " Value")[$MatchTest]
        $MatchTableInsert = [PSCustomObject]@{
            'File'               = ((($HashCalcTable) | Where-Object -FilterScript {$_.($HashOp + " Value") -EQ $MatchSet})).File
            ($HashOp + " Value") = "$MatchSet"
            "Compared Hash"      = "$ImportedHash"
            "Match"              = "Yes"
        }
        $MatchTable = $MatchTable + $MatchTableInsert
        $MatchTest = $Null
        }
    $CombinedTables = $MatchTable + $NoMatchTable
    }
    return $CombinedTables
}

$AskOpPick  = AskRun
$FilePath   = AskFile

switch ($AskOpPick) {  
    1 {
        if ($FilePath.Count -eq 1) {
            $CreateHashReturn = CreateHashFile
            $CreateHashReturn
        }
        else {
            $CreateHashReturn = CreateHashFolder
            $CreateHashReturn
        }
    }
    2 {
        if ($FilePath.Count -eq 1) {
            $VerifyHashReturn = VerifyHashFile
            $VerifyHashReturn | Format-List
        }
        else {
            $VerifyHashReturn = VerifyHashFolder
            $VerifyHashReturn | Format-List

            Write-Host -ForegroundColor Yellow ('Tip:

$VerifyHashReturn | Export-CSV
$VerifyHashReturn | Where-Object -Property Match -EQ "Yes"
')
        }
    }
}
