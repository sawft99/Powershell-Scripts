$Folder = 'C:\Example'
$Prefix = 'ABC'
$PrfLen = $Prefix.Length
$Suffix = '123'
$SufLen = $Suffix.Length

Clear-Host

Function FilePrefixLoop {
    $PrefixFiles = Get-ChildItem -Path $Folder -Recurse | Where-Object {$_.BaseName.StartsWith("$Prefix")}
    Write-Host "Changed Prefix:"
    Write-Host ""
    $PrefixFiles| ForEach-Object {
        $RF = $_.BaseName[($PrfLen)..$_.BaseName.Length] -join ""
        Write-Host $_.BaseName -> $RF
        Rename-Item -Path $_.FullName -NewName ($RF + $_.Extension)
        Write-Host
    }
    Write-Host ""
}

Function FileSuffixLoop {
    $SuffixFiles = Get-ChildItem -Path $Folder -Recurse | Where-Object {$_.BaseName.EndsWith("$Suffix")}
    Write-Host "Changed Suffix:"
    Write-Host ""
    $SuffixFiles| ForEach-Object {
        $Diff = $_.BaseName.Length - $SufLen - 1
        $RF = $_.BaseName[0..$Diff] -join ""
        Write-Host $_.BaseName -> $RF
        Rename-Item -Path $_.FullName -NewName ($RF + $_.Extension)
    }
    Write-Host ""
}

FilePrefixLoop
FileSuffixLoop
