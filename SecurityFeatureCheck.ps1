#Check statuses for Windows security features
#https://learn.microsoft.com/en-us/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity

$SecurityAbilities = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard

#$VBSValue = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name 'EnableVirtualizationBasedSecurity' -ErrorAction SilentlyContinue)
#$PlatformSecurityValue = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name 'RequirePlatformSecurityFeatures' -ErrorAction SilentlyContinue)
#$UEFILockValue = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name 'Locked' -ErrorAction SilentlyContinue)
#$HVCIEnable = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name 'Enabled' -ErrorAction SilentlyContinue)
#$HVCILock = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name 'Locked' -ErrorAction SilentlyContinue)

Clear-Host

Write-Output '
---------
Available
---------
'

if ($null -eq $SecurityAbilities.AvailableSecurityProperties) {
    Write-Output 'Issue getting available security properties'
    #$LASTEXITCODE = 1
    #exit $LASTEXITCODE
}

if ($null -ne $SecurityAbilities.AvailableSecurityProperties) {
    if (0 -in $SecurityAbilities.AvailableSecurityProperties) {
        Write-Output 'No security properties available'
    }
    if (1 -in $SecurityAbilities.AvailableSecurityProperties) {
        Write-Output 'Hypervisor support available'
    } else {
        Write-Output 'Hypervisor support NOT available'
    }
    if (2 -in $SecurityAbilities.AvailableSecurityProperties) {
        Write-Output 'Secure Boot support available'
    } else {
        Write-Output 'Secure Boot support NOT available'
    }
    if (3 -in $SecurityAbilities.AvailableSecurityProperties) {
        Write-Output 'DMA support available'
    } else {
        Write-Output 'DMA support NOT available'
    }
    if (4 -in $SecurityAbilities.AvailableSecurityProperties) {
        Write-Output 'Secure Memory Overwrite support available'
    } else {
        Write-Output 'Secure Memory Overwrite support NOT available'
    }
    if (5 -in $SecurityAbilities.AvailableSecurityProperties) {
        Write-Output 'NX Protection support available'
    } else {
        Write-Output 'NX Protection support NOT available'
    }
    if (6 -in $SecurityAbilities.AvailableSecurityProperties) {
        Write-Output 'SMM mitigation support available'
    } else {
        Write-Output 'SMM mitigation support NOT available'
    }
    if (7 -in $SecurityAbilities.AvailableSecurityProperties) {
        Write-Output 'MBEC/GMET support available'
    } else {
        Write-Output 'MBEC/GMET support NOT available'
    }
    if (8 -in $SecurityAbilities.AvailableSecurityProperties) {
        Write-Output 'APIC virtualization support available'
    } else {
        Write-Output 'APIC virtualization support NOT available'
    }
}

Write-Output '
--------
Required
--------
'

if ($null -eq $SecurityAbilities.RequiredSecurityProperties) {
    Write-Output 'Issue getting required security properties'
    #$LASTEXITCODE = 1
    #exit $LASTEXITCODE
}

if ($null -ne $SecurityAbilities.RequiredSecurityProperties) {
    if (0 -in $SecurityAbilities.RequiredSecurityProperties) {
        Write-Output 'No security properties required'
    } else {
        if (1 -in $SecurityAbilities.RequiredSecurityProperties) {
            Write-Output 'Hypervisor support required'
        } else {
            Write-Output 'Hypervisor support NOT required'
        }
        if (2 -in $SecurityAbilities.RequiredSecurityProperties) {
            Write-Output 'Secure Boot support required'
        } else {
            Write-Output 'Secure Boot support NOT required'
        }
        if (3 -in $SecurityAbilities.RequiredSecurityProperties) {
            Write-Output 'DMA support required'
        } else {
            Write-Output 'DMA support NOT required'
        }
        if (4 -in $SecurityAbilities.RequiredSecurityProperties) {
            Write-Output 'Secure Memory Overwrite support required'
        } else {
            Write-Output 'Secure Memory Overwrite support NOT required'
        }
        if (5 -in $SecurityAbilities.RequiredSecurityProperties) {
            Write-Output 'NX Protection support required'
        } else {
            Write-Output 'NX Protection support NOT required'
        }
        if (6 -in $SecurityAbilities.RequiredSecurityProperties) {
            Write-Output 'SMM mitigation support required'
        } else {
            Write-Output 'SMM mitigation support NOT required'
        }
        if (7 -in $SecurityAbilities.RequiredSecurityProperties) {
            Write-Output 'MBEC/GMET support required'
        } else {
            Write-Output 'MBEC/GMET support NOT required'
        }
    }
}

Write-Output '
----------
Configured
----------
'

if ($null -eq $SecurityAbilities.SecurityServicesConfigured) {
    Write-Output 'Issue getting configured security properties'
    #$LASTEXITCODE = 1
    #exit $LASTEXITCODE
}

if ($LASTEXITCODE -ne 1) {
    if (0 -in $SecurityAbilities.SecurityServicesConfigured) {
        Write-Output 'No security properties configured'
    } else {
        if (1 -in $SecurityAbilities.SecurityServicesConfigured) {
            Write-Output 'Credential Guard is cofigured'
        } else {
            Write-Output 'Credential Guard is NOT cofigured'
        }
        if (2 -in $SecurityAbilities.SecurityServicesConfigured) {
            Write-Output 'Memory Integrity is configured'
        } else {
            Write-Output 'Memory Integrity is NOT configured'
        }
        if (3 -in $SecurityAbilities.SecurityServicesConfigured) {
            Write-Output 'System Guard Secure Launch is configured'
        } else {
            Write-Output 'System Guard Secure Launch is NOT configured'
        }
        if (4 -in $SecurityAbilities.SecurityServicesConfigured) {
            Write-Output 'SMM Firmware Measurement is configured'
        } else {
            Write-Output 'SMM Firmware Measurement is NOT configured'
        }
        if (5 -in $SecurityAbilities.SecurityServicesConfigured) {
            Write-Output 'Kernel-mode Hardware-enforced Stack Protection is configured'
        } elseif (6 -in $SecurityAbilities.SecurityServicesConfigured) {
            Write-Output 'Kernel-mode Hardware-enforced Stack Protection is configured to AUDIT'
        } else {
            Write-Output 'Kernel-mode Hardware-enforced Stack Protection is NOT configured'
        }

        if (7 -in $SecurityAbilities.SecurityServicesConfigured) {
            Write-Output 'Hypervisor-Enforced Paging Translation is configured'
        } else {
            Write-Output 'Hypervisor-Enforced Paging Translation is NOT configured'
        }
    }
}

Write-Output '
-------
Running
-------
'

if ($null -eq $SecurityAbilities.SecurityServicesRunning) {
    Write-Output 'Issue getting running security properties'
    $LASTEXITCODE = 1
    #exit $LASTEXITCODE
}

if ($null -ne $SecurityAbilities.SecurityServicesRunning) {
    if (0 -in $SecurityAbilities.SecurityServicesRunning) {
        Write-Output 'No security services running'
    } else {
        if (1 -in $SecurityAbilities.SecurityServicesRunning) {
            Write-Output 'Credential Guard is running'
        } else {
            Write-Output 'Credential Guard is NOT running'
        }
        if (2 -in $SecurityAbilities.SecurityServicesRunning) {
            Write-Output 'Memory Integrity is running'
        } else {
            Write-Output 'Memory Integrity is NOT running'
        }
        if (3 -in $SecurityAbilities.SecurityServicesRunning) {
            Write-Output 'System Guard Secure Launch is running'
        } else {
            Write-Output 'System Guard Secure Launch is NOT running'
        }
        if (4 -in $SecurityAbilities.SecurityServicesRunning) {
            Write-Output 'SMM Firmware Measurement is running'
        } else {
            Write-Output 'SMM Firmware Measurement is NOT running'
        }
        if (5 -in $SecurityAbilities.SecurityServicesRunning) {
            Write-Output 'Kernel-mode Hardware-enforced Stack Protection is running'
        } elseif (6 -in $SecurityAbilities.SecurityServicesRunning) {
            Write-Output 'Kernel-mode Hardware-enforced Stack Protection is running in AUDIT'
        } else {
            Write-Output 'Kernel-mode Hardware-enforced Stack Protection is NOT running'
        }
        if (7 -in $SecurityAbilities.SecurityServicesRunning) {
            Write-Output 'Hypervisor-Enforced Paging Translation is running'
        } else {
            Write-Output 'Hypervisor-Enforced Paging Translation is NOT running'
        }
    }
}

Write-Output '
-----------------------
Code Integrity Enforced
-----------------------
'

if ($SecurityAbilities.CodeIntegrityPolicyEnforcementStatus -eq 0) {
    Write-Output 'Code integrity policy enforcement status is set to: OFF'
} elseif ($SecurityAbilities.CodeIntegrityPolicyEnforcementStatus -eq 1) {
    Write-Output 'Code integrity policy enforcement status is set to: AUDIT'
} elseif ($SecurityAbilities.CodeIntegrityPolicyEnforcementStatus -eq 2) {
    Write-Output 'Code integrity policy enforcement status is set to: ENFORCED'
} else {
    Write-Output 'Code integrity policy enforcement status is set to: UNKNOWN'
}

Write-Output '
-------------
SMM Isolation
-------------
'

if ($null -eq $SecurityAbilities.SmmIsolationLevel) {
    Write-Output 'Issue getting SMM isolation level'
} elseif ($SecurityAbilities.SmmIsolationLevel -eq 1) {
    Write-Output "SMM isolation level: FULL ($($SecurityAbilities.SmmIsolationLevel))"
} elseif ($SecurityAbilities.SmmIsolationLevel -eq 2) {
    Write-Output "SMM isolation level: PARTIAL ($($SecurityAbilities.SmmIsolationLevel))"
} elseif ($SecurityAbilities.SmmIsolationLevel -eq 3) {
    Write-Output "SMM isolation level: NONE ($($SecurityAbilities.SmmIsolationLevel))"
} elseif ($SecurityAbilities.SmmIsolationLevel -eq 0) {
    Write-Output "SMM isolation level: DISABLED/UNSUPPORTED ($($SecurityAbilities.SmmIsolationLevel))"
} else {
    Write-Output "SMM isolation level: UNKNOWN"
}

Write-Output '
---------------------------------
User Mode Code Integrity Enforced
---------------------------------
'

if ($SecurityAbilities.UsermodeCodeIntegrityPolicyEnforcementStatus -eq 0) {
    Write-Output 'User code integrity policy enforcement status is set to: OFF'
} elseif ($SecurityAbilities.CodeIntegrityPolicyEnforcementStatus -eq 1) {
    Write-Output 'User code integrity policy enforcement status is set to: AUDIT'
} elseif ($SecurityAbilities.CodeIntegrityPolicyEnforcementStatus -eq 2) {
    Write-Output 'User code integrity policy enforcement status is set to: ENFORCED'
} else {
    Write-Output 'User code integrity policy enforcement status is set to: UNKNOWN'
}

Write-Output '
----------
VBS Status
----------
'

if ($SecurityAbilities.VirtualizationBasedSecurityStatus -eq 0) {
    Write-Output 'VBS is NOT enabled'
} elseif ($SecurityAbilities.VirtualizationBasedSecurityStatus -eq 1) {
    Write-Output 'VBS is set enabled but NOT running'
} elseif ($SecurityAbilities.VirtualizationBasedSecurityStatus -eq 2) {
    Write-Output 'VBS is running'
} else {
    Write-Output 'VBS status is UNKNOWN'
}

Write-Output '
------------
VM Isolation
------------
'

if ($null -eq $SecurityAbilities.VirtualMachineIsolation) {
    Write-Output 'Issue getting VM isolation info'
} else {
    Write-Output "VM isolation enabled: $($SecurityAbilities.VirtualMachineIsolation)"
}

Write-Output '
-----------------------
VM Isolation Properties
-----------------------
'

if ($null -eq $SecurityAbilities.VirtualMachineIsolationProperties) {
    Write-Output 'Issue getting VM isolation properties'
} else {
    Write-Output "AMD SEV-SNP available: $(1 -in $SecurityAbilities.VirtualMachineIsolationProperties)"
    Write-Output "VBS available: $(2 -in $SecurityAbilities.VirtualMachineIsolationProperties)"
    Write-Output "Intel TDX available: $(3 -in $SecurityAbilities.VirtualMachineIsolationProperties)"
}

Write-Output ''
