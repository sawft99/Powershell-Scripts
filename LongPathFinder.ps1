#Requires -RunAsAdministrator
#Find paths longer than supported amount
#Windows max w/ long path: 32,767
#Windows max: 260
#OneDrive max: 250
$MaxLength = 250
#Reg key for long path setting
$LongPathsKey = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem')
#Ask to change reg key value
$AskToSetLongPaths = $false
#Only check for long path settings
$OnlyCheckSettings = $true
#User folder to check, will be overriden by $AllUsers if set to $true
[System.IO.DirectoryInfo]$Root = $env:USERPROFILE
#Recurse all user folders, will override $Root value if set to $true
$AllUsers = $false

#-----------

$Error.Clear()
Clear-Host

Write-Host '
================
Long Path Finder
================
'
#Variable checks
if ($MaxLength -notin 1..32767) {
    Write-Host -ForegroundColor Red 'Enter a valid number
    '
    exit 2
}

if (($AskToSetLongPaths -ne $true) -and ($AskToSetLongPaths -ne $false)) {
    Write-Host -ForegroundColor Red '$AskToSetLongPaths needs to be $true or $false
    '
    exit 2
}

if (($OnlyCheckSettings -ne $true) -and ($OnlyCheckSettings -ne $false)) {
    Write-Host -ForegroundColor Red '$OnlyCheckSettings needs to be $true or $false
    '
    exit 2
}

if ($OnlyCheckSettings -eq $false) {
    if (($AllUsers -ne $true) -and ($AllUsers -ne $false)) {
        Write-Host -ForegroundColor Red '$AllUsers needs to be $true or $false
        '
        exit 2
    } elseif ($AllUsers -eq $true) {
        #Check if $Root folder exists
        [System.IO.DirectoryInfo]$Root = $env:SystemDrive + '\' + 'Users'
        if (($Root.Exists -eq $false) -or ($null -eq $Root.Exists)) {
            Write-Host -ForegroundColor Red 'Could not find $Root folder
            '
            exit 2
        }
        #If $AllUsers = $true get all users folders info
        $UserFolders = Get-ChildItem $Root
        Write-Host "Users: $($UserFolders.Count)
        "
        $UserCount = 1
        $AllItems = foreach ($User in $UserFolders) {
            Write-Host "Checking user ($UserCount) $($User.Name)"
            $UserCount = $UserCount + 1
            Get-ChildItem -Path $User.FullName -Recurse -Force -ErrorAction SilentlyContinue    
        }
        Write-Host ''
    } elseif ($AllUsers -eq $false) {
        if (($Root.Exists -eq $false) -or ($null -eq $Root.Exists)) {
            Write-Host -ForegroundColor Red 'Could not find $Root folder
            '
            exit 2
        }
        $AllItems = Get-ChildItem -Path $Root -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host -ForegroundColor Red '$AllUsers needs to be $true or $false
        '
        exit 2
    }
    #Find only files/folders that are over the $MaxLength
    $LongItems = $AllItems | Where-Object {$_.FullName.Length -gt $MaxLength}

    #Report findings
    if ($Null -eq $LongItems) {
        Write-Host -ForegroundColor Green 'No long paths found
        '
    } else {
        $LongItems | Sort-Object -Property FullName | Format-Table -Property FullName -HideTableHeaders
    }
}

Write-Host 'Long Paths Enabled: ' -NoNewline

switch ($LongPathsKey.LongPathsEnabled) {
    0 {
        Write-Host -ForegroundColor Yellow 'No'
    }
    1 {
        Write-Host -ForegroundColor Green 'Yes'
    }
    Default {
        Write-Host -ForegroundColor Red 'Key missing'
    }
}

#If $AskToSetLongPaths = $true ask to change registry key
if ($null -ne $LongPathsKey.LongPathsEnabled) {
    if ($AskToSetLongPaths -eq $true) {
        Write-Host '
        0 = Disable 
        1 = Enable
        2 = Skip
        '
        do {
            $EnableLongPaths = Read-Host -Prompt 'Enable long paths?'
            if (($EnableLongPaths -notin 0..2) -or ($null -eq $EnableLongPaths) -or ($EnableLongPaths.Length -lt 1)) {
                Write-Host -ForegroundColor Red 'Enter 0,1,or 2 only'
            }
        } until (
            (($EnableLongPaths -in 0..2) -and ($null -ne $EnableLongPaths) -and ($EnableLongPaths.Length -gt 0))
        )
        Write-Host ''
        if ($EnableLongPaths -eq $LongPathsKey.LongPathsEnabled) {
            Write-Host -ForegroundColor Yellow 'Selection already matches registry value
            '
        } else {
            if ($EnableLongPaths -eq 1) {
                Set-ItemProperty -Path $LongPathsKey.PSPath -Name 'LongPathsEnabled' -Value 1
                $LongPathsKey = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem')
                if ($LongPathsKey.LongPathsEnabled -ne 1) {
                    Write-Host -ForegroundColor Red 'Registry key was not changed
                    '
                } else {
                    Write-Host -ForegroundColor Green 'Registry key was changed
                    '
                }
            } elseif ($EnableLongPaths -eq 0) {
                Set-ItemProperty -Path $LongPathsKey.PSPath -Name 'LongPathsEnabled' -Value 0
                $LongPathsKey = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem')
                if ($LongPathsKey.LongPathsEnabled -ne 0) {
                    Write-Host -ForegroundColor Red 'Registry key was not changed
                    '
                } else {
                    Write-Host -ForegroundColor Green 'Registry key was changed
                    '
                }
            } elseif ($EnableLongPaths -eq 2) {
                Write-Host -ForegroundColor Yellow 'Skipped adjusting registry key
                '
            } else {
                Write-Host -ForegroundColor Red '$EnableLongPaths is not 0,1,or 2
                '
            }
        }
    } else {
        Write-Host ''
    }
}

#Report errors if any
if ($Error.Count -gt 0) {
    #Write-Host -ForegroundColor Red 'Errors detected, review $Error'
}
