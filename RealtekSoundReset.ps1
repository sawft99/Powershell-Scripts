#Restart realtek hardware for headphone issues

$Error.clear()

#Check if already elevated. Will relaunch elevated if not.
$ElevCheck = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if ($ElevCheck -eq $false) {
    Start-Process powershell.exe -Verb runas -ArgumentList "-File", "$PSCommandPath"
    timeout.exe /t 3
    Exit
}
else {
    #Check for Realtek sound hardware
    $HardwareCheck = (Get-PnpDevice -FriendlyName 'Realtek(R) Audio' -ErrorAction SilentlyContinue)
    $HardwareID = $HardwareCheck.InstanceId
    if ($HardwareCheck.Problem -eq "CM_PROB_DISABLED") {
        Write-Host -ForegroundColor Yellow "Realtek audio device already disabled. Exiting..."
        timeout.exe /t 5
        Exit
    }
    if ($Null -eq $HardwareID.Count -or $HardwareID.Count -eq 0) {
        Write-Host -ForegroundColor Red "Could not find Realtek audio device..."
        Write-Host ""
        Pause
        Exit
    }
    $Error.Clear()
    #Disable audio device
    Write-Host "Disabling adapter..."
    Disable-PnpDevice "$HardwareID" -Confirm:$false -ErrorAction SilentlyContinue
    if ($Error.Count -gt 0) {
        Write-Host ""
        Write-Host -ForegroundColor Red "Issue disabling. Check that nothing besides the system is using sound and then rerun."
        SndVol.exe
        Write-Host ""
        Pause
        Exit
    } 
    else {
        #Wait several seconds to allow operation
        $Error.Clear()
        Write-Host ""
        Write-Host -ForegroundColor Green "Disabled successfully!"
        timeout.exe /nobreak /t 3
        Write-Host ""
        #Enable audio device
        Write-Host "Enabling adapter..."
        Enable-PnpDevice "$HardwareID" -Confirm:$false
        Write-Host ""
        if ($Error.Count -gt 0) {
            Write-Host -ForegroundColor Red "Issue enabling"
            Write-Host ""
            Pause
            Exit
        } else {
            Write-Host -ForegroundColor Green "Enabled successfully!"
        }
    timeout /t 5
    Exit
    }
}
