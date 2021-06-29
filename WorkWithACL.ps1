$Folder = "C:\Test1"

$CurrentRules = Get-Acl $Folder
$CurrentRulesFormatted = ($CurrentRules).Access | Format-Table -Wrap -Property IdentityReference, FileSystemRights, AccessControlType, IsInherited
$CurrentRulesFormatted

$AskEdit = Read-host -Prompt "Edit permissions?"

if ($AskEdit -in "Y", "Yes") {
    
    function AskTask {
    [int]$global:AskTask = Read-Host -Prompt "
Tasks:
        
1. Edit current access
2. Add access rules
3. Remove access rules
4. Change owner
5. Change inheritance

Select option#"
        if ($global:AskTask -notin 1,2,3,4,5) {
            Clear-Host
            Write-Host ""
            Write-Host "Select a valid option" -ForegroundColor Red
            AskTask    
        }
    }


    AskTask
    Clear-Host

    if ($global:AskTask -eq 1) {
        Write-Host "option 1"
    }
    if ($global:AskTask -eq 2) {
        Write-Host "option 2"
    }
    if ($global:AskTask -eq 3) {
        Write-Host "option 3"
    }
    if ($global:AskTask -eq 4) {
        Write-Host "option 4"
    }
    if ($global:AskTask -eq 5) {
        Write-Host "option 5"
    }
}
else {
    Write-Host "Done"
    #exit
}

$c = 0
$x = $CurrentRules.Access.IdentityReference

foreach ($y in $x) {
    $y | Add-Member -MemberType NoteProperty -Name Line -Value ($c++) -Force
}

#$x | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name Line -Value ($c++) -Force}
$x