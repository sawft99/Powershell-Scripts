#Requires -RunAsAdministrator
#Script that will auto download and install NuGet provider, PowershellGet module, and Autopilot script from PSGallery. It will then run the script to upload the config to your autopilot instance. You only need to provide valid credentials to join the device when prompted.
Clear-Host
$Error.Clear()
#Elevation check
$ElevationCheck = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($ElevationCheck -eq $false) {
    Write-Host "Not running as admin or not elevated, exiting...
    "
    throw
}

#Prereq
# - .NET Framework 4.5
# - Ability to use TLS 1.2

#Variables
$Tenant = 'example.onmicrosoft.com'
#Group tag that will show in Autopilot console
$Tag = 'User Driven'
$ProgressPreference = 'SilentlyContinue'

Write-Host -ForegroundColor Green "
===============
Start of script
===============
"

# Check if NuGet package provider and module are installed
function NuPackCheck {
    $i = 0
    $MinVer = [Version]::new(2,8,5,201)
    do {
        Write-Host "NuGet Package Provider: Checking if installed...
        "
        $NuPackCheck = Get-PackageProvider | Where-Object {$_.Name -eq 'nuget'}
        if ($Null -eq $NuPackCheck) {
            Write-Host "NuGet Package Provider: Not found, installing...
            "
            Install-PackageProvider -Name NuGet -Force -MinimumVersion $MinVer -Scope AllUsers
        } else {
            Write-Host "NuGet Package Provider: Found, continuing...
            "
        }
        $NuPackCheck = Get-PackageProvider | Where-Object {$_.Name -eq 'nuget'}
        $NuPackCheck = $Null -eq $NuPackCheck
        $i++
    } until (($NuPackCheck -eq $false) -or ($i -gt 2))
    $NuPackCheck
}

#Check for NuGet module
function NuModuleCheck {
    $i = 0
    $MinVer = [Version]::new(1,3,3)
    do {
        Write-Host "NuGet Module: Checking if installed...
        "
        $NuModuleCheck = Get-Module -ListAvailable | Where-Object {$_.Name -eq 'NuGet'}
        if ($Null -eq $NuModuleCheck) {
            Write-Host "NuGet Module: Not found, installing...
            "
            Install-Module -Name 'NuGet' -AllowClobber -Force -Scope AllUsers -MinimumVersion $MinVer -Confirm:$false
        } else {
            Write-Host "NuGet Module: Found, continuing...
            "
        }
        Write-Host "NuGet Module: Checking if up to date...
            "
        if ($NuModuleCheck.Version -lt $MinVer) {
            Write-Host "NuGet Module: Not up to date, updating...
            "
            Update-Module -Name 'NuGet' -Force -Confirm:$false
        } else {
            Write-Host "NuGet Module: Up to date, continuing...
            "
        }
        $NuModuleCheck = Get-Module -ListAvailable | Where-Object {$_.Name -eq 'NuGet'}
        $NuModuleCheck = $Null -eq $NuModuleCheck
        $i++
    } until (($NuModuleCheck -eq $false) -or ($i -gt 2))
    $NuModuleCheck
}

#Get original PSGallery trust level
function OriginalPSGal {
    Write-Host "PSGallery: Checking and storing current trust level...
    "
    $OriginalPSGalTrust = (Get-PSRepository | Where-Object -Property 'Name' -eq "PSGallery").InstallationPolicy
    $OriginalPSGalTrust
}

#Set new PSGallery trust level
function NewPSGalTrust {
    if ($OriginalPSGalTrust -ne 'Trusted') {
        Write-Host 'PSGallery: Setting repository to "Trusted"...
        '
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'
    } else {
        Write-Host 'PSGallery: Repository already set to "Trusted", continuing...
        '
    }
    $NewPSGalTrust = (Get-PSRepository | Where-Object -Property 'Name' -eq "PSGallery").InstallationPolicy
    $NewPSGalTrust = $Null -eq $NewPSGalTrust
    $NewPSGalTrust
}

#Check for PowerShellGet module. Install if missing. Update if less than version 2.2.5
function PSGetCheck {
    $i = 0
    $MinVer = [Version]::new(2,2,5)
    do {
        Write-Host "PowerShellGet Module: Checking if installed...
        "
        $PSGetCheck = Get-Module -All -ListAvailable | Where-Object -Property 'Name' -eq 'PowerShellGet'
        if ($Null -eq $PSGetCheck) {
            Write-Host "PowerShellGet Module: Not installed, installing...
            "
            Install-Module -Name PowerShellGet -MinimumVersion $MinVer -AllowClobber -Force -Scope AllUsers -Confirm:$false
        } else {
            Write-Host "PowerShellGet Module: Installed, continuing...
            "
        }
        Write-Host "PowerShellGet Module: Checking if up to date...
        "
        if ((($PSGetCheck.Version -ge $MinVer).count -le 0) -and ($Null -ne $PSGetCheck)) {
            Write-Host "PowerShellGet Module: Not up to date, updating...
            "
            Install-Module -Name PowerShellGet -MinimumVersion $MinVer -AllowClobber -Force -Scope AllUsers -Confirm:$false
            Update-Module -Name 'PowerShellGet' -Force -Confirm:$false
        } else {
            Write-Host "PowerShellGet Module: Up to date, continuing...
            "
        }
        $PSGetCheck = Get-Module -All -ListAvailable | Where-Object {($_.Name -eq 'PowerShellGet') -and ($_.Version -ge $MinVer)}
        $PSGetCheck = $Null -eq $PSGetCheck
        $i++
    } until (($PSGetCheck -eq $false) -or ($i -gt 2))
    $PSGetCheck
}

#Check for Upload-WindowsAutopilotDeviceInfo module. Install if missing. Update if less than version 1.2.1.0
function APCheck {
    $ArchCheck = Test-Path $env:ProgramW6432
    if ($ArchCheck -eq $true) {
        Write-Host "Autopilot Script: Detected as 64 bit, continuing...
        "
    } else {
        Write-Host "Autopilot Script: Detected as 32 bit, continuing...
        "
    }
    $i = 0
    $MinVer = [Version]::new(1,2,1,0)
    do {
        Write-Host "Autopilot Script: Checking if installed...
        "
        if (($ArchCheck -eq $true) -and (!(Test-Path "$env:ProgramW6432\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1"))) {
            Write-Host "Autopilot Script: Not found, installing...
            "
            Install-Script -Name 'Upload-WindowsAutopilotDeviceInfo' -Force -Scope AllUsers -MinimumVersion $MinVer -Confirm:$false
            $APCheck = Test-Path "$env:ProgramW6432\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1"
        } #elseif (($ArchCheck -eq $true) -and (Test-Path "$env:ProgramW6432\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1")) {
        #    Write-Host "Autopilot Script: Script is installed, updating...
        #    "
        #    Update-Script -Name 'Upload-WindowsAutopilotDeviceInfo' -Force -RequiredVersion $MinVer -Confirm:$false
        #    $APCheck = Test-Path "$env:ProgramW6432\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1"
        #}
        elseif (($ArchCheck -eq $false) -and (!(Test-Path "${env:ProgramFiles(x86)}\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1"))) {
            Write-Host "Autopilot Script: Not found, installing...
            "
            Install-Script -Name 'Upload-WindowsAutopilotDeviceInfo' -Force -Scope AllUsers -MinimumVersion $MinVer -Confirm:$false
            $APCheck = Test-Path "${env:ProgramFiles(x86)}\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1"
        } #elseif (($ArchCheck -eq $false) -and (Test-Path "${env:ProgramFiles(x86)}\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1")) {
        #    Write-Host "Autopilot Script: Script is installed, updating...
        #    "
        #    Update-Script -Name 'Upload-WindowsAutopilotDeviceInfo' -Force -RequiredVersion $MinVer -Confirm:$false
        #    $APCheck = Test-Path "${env:ProgramFiles(x86)}\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1"
        #}
        else {
            Write-Host "Autopilot Script: Found, continuing...
            "
        }
        $i++
    } until (($APCheck -eq $true) -or ($i -gt 2))
    $APCheck
}

#Get original Execution Policy 
function OriginalExecPolicy {
    Write-Host 'Execution Policy: Checking and storing current execution policy...
    '
    $OriginalExecPolicy = Get-ExecutionPolicy -Scope 'LocalMachine'
    $OriginalExecPolicy
}

#Set new Execution Policy
function NewExecPolicy {
    if ($OrigninalExecPolicy -ne 'Unrestricted') {
        Write-Host 'Execution Policy: Setting policy to "Unrestricted"...
        '
        Set-ExecutionPolicy -ExecutionPolicy 'Unrestricted' -Force -Scope 'LocalMachine' 
        $NewExecPolicy = Get-ExecutionPolicy -Scope 'LocalMachine'
    } else {
        Write-Host 'Execution Policy: Policy already set to "Unrestricted", continuing...
        '
        $NewExecPolicy = 'Unrestricted'
    }
    $NewExecPolicy
}

#Run Autopilot info upload
function APUpload {
    Write-Host "Autopilot Script: Running...
    "
    $ArchCheck = Test-Path $env:ProgramW6432
    if ($ArchCheck -eq $true) {
        $Script = "$env:ProgramW6432\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1"
    } else {
        $Script = "${env:ProgramFiles(x86)}\WindowsPowerShell\Scripts\Upload-WindowsAutopilotDeviceInfo.ps1"
    }
    $APUpload = Invoke-Command -ScriptBlock {
        param (
            $Script,
            $Tenant,
            $Tag
        )
        & $Script -TenantName $Tenant -Grouptag $Tag -ErrorAction 'Continue'
    } -ArgumentList $Script, $Tenant, $Tag, 'Continue' -ErrorAction Continue
    $APUpload
}

#Set PSGallery trust back to original setting
function PSGalleryReset {
    Write-Host "PSGallery: Resetting back to original trust level...
    "
    if ((Get-PSRepository | where-Object -Property Name -eq "PSGallery" | Select-Object -Property InstallationPolicy).InstallationPolicy -ne $OriginalPSGalTrust) {
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy $OriginalPSGalTrust
    } else {
        Write-Host "PSGallery: Setting already matches, continuing...
        "
    }
}

#Set Execution Policy back to original setting
function ExecPolicyReset {
    Write-Host "Execution Policy: Resetting back to original policy...
    "
    if ($NewExecPolicy -ne $OrigninalExecPolicy) {
        Set-ExecutionPolicy -ExecutionPolicy $OrigninalExecPolicy -Scope LocalMachine -Force
    } else {
        Write-Host "Execution Policy: Setting already matches, continuing...
        "
    }
}

#Run functions
try {
    $OrigninalExecPolicy = OriginalExecPolicy
    $OriginalPSGalTrust = OriginalPSGal
    $NuPackCheck = NuPackCheck
    if ($NuPackCheck -eq $true) {
        Write-Host "NuGet Package Provider: Error installing, reverting to original settings..."
        PSGalleryReset
        ExecPolicyReset
        throw
    }
    $NewPSGalTrust = NewPSGalTrust
    if ($NewPSGalTrust -eq 'Error') {
        Write-Host "PSGallery: Setting trust failed, reverting to original settings..."
        PSGalleryReset
        ExecPolicyReset
        throw
    }
    $NewExecPolicy = NewExecPolicy
    if ($NewExecPolicy -eq 'Error') {
        Write-Host "Execution Policy: Setting trust failed, reverting to original settings..."
        PSGalleryReset
        ExecPolicyReset
        throw
    }
    $NuModuleCheck = NuModuleCheck
    if ($NuModuleCheck -eq $true) {
        Write-Host "NuGet Module: Error installing, reverting to original settings..."
        PSGalleryReset
        ExecPolicyReset
        throw
    }
    $PSGetCheck = PSGetCheck
    if ($PSGetCheck -eq $true) {
        Write-Host "PowerShellGet Module: Install or update failed, reverting to original settings...
        "
        PSGalleryReset
        ExecPolicyReset
    } else {
        $APCheck = APCheck
        if (($APCheck -eq $false) -or ($null -eq $APCheck)) {
            Write-Host -ForegroundColor Red "Autopilot Script: Error installing script, reverting to original settings...
            "
            PSGalleryReset
            ExecPolicyReset
        } else {
            try {
                $APUpload = APUpload
                Write-Host ""
            } catch {
                Write-Host -ForegroundColor Red "Autopilot Script: Error running script, reverting to original settings...
                "
                PSGalleryReset
                ExecPolicyReset
            }
        }
    }
} catch {
    Write-Host -ForegroundColor Red "An error occured somewhere...
    "
    Write-Host -ForegroundColor Red "Attempting to revert back to original settings...
    "
    if ($Null -ne $OriginalPSGalTrust) {
        PSGalleryReset
    } else {
        Write-Host -ForegroundColor Red "Unable to restore original trust setting...
        "
    }
    if ($Null -ne $OrigninalExecPolicy) {
        ExecPolicyReset
    } else {
        Write-Host -ForegroundColor Red "Unable to restore original execution policy..."
    }
}

Write-Host -ForegroundColor Green "=============
End of script
============="
