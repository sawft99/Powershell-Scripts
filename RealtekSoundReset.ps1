#Restart realtek hardware for headphone issues

$Error.clear()

#Check if already elevated. Will relaunch elevated if not.
$ElevCheck = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')

if ($ElevCheck -eq $fasle) {
    Start-Process $PSCommandPath -Verb runas
    timeout.exe /nobreak /t 3
} 
else {
    Start-Process -FilePath Powershell -Verb runas -ArgumentList {
        #Check for Realtek sound hardware
        $HardwareCheck = (Get-PnpDevice -FriendlyName 'Realtek(R) Audio' -ErrorAction SilentlyContinue).InstanceID
        if ($Null -eq $HardwareCheck -or $HardwareCheck.Count -eq 0) {
            Write-Host -ForegroundColor Red "Could not find Realtek audio device..."
            Write-Host ""
            Pause
            Exit
        }
        $Error.Clear()
        #Disable audio device
        Write-Host "Disabling adapter..."
        Disable-PnpDevice "$HardwareCheck" -Confirm:$false -ErrorAction SilentlyContinue
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
            timeout.exe /nobreak /t 3
            $Error.Clear()
            Write-Host ""
            Write-Host "Disabled successfully!"
            Write-Host ""
            #Enable audio device
            Write-Host "Enabling adapter..."
            Enable-PnpDevice "$HardwareCheck" -Confirm:$false
            Write-Host ""
            if ($Error.Count -gt 0) {
                Write-Host -ForegroundColor Red "Issue enabling"
                Write-Host ""
                Pause
                Exit
            } else {
                Write-Host "Enabled successfully!"
            }
        timeout /t 3
        Exit
        }
    }
}
