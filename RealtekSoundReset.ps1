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
    #Stop Audio services
    Write-Host ""
    Write-Host Stopping services...
    Write-Host ""
    $Audio1 = Get-Service Audiosrv -ErrorAction SilentlyContinue
    if ($Audio1.Count -eq 1) {
        Stop-Service $Audio1
        Write-Host Stopped $Audio1.DisplayName
        Write-Host ""
    }
    $Audio2 = Get-Service AudioEndpointBuilder -ErrorAction SilentlyContinue
        if ($Audio2.Count -eq 1) {
        Stop-Service $Audio2
        Write-Host Stopped $Audio2.DisplayName
        Write-Host ""
    }
    $WaveAudio1 = Get-Service WavesSysSvc -ErrorAction SilentlyContinue
        if ($WaveAudio1.Count -eq 1) {
        Stop-Service $WaveAudio1
        Write-Host Stopped $WaveAudio1.DisplayName
        Write-Host ""
    }
    $WaveAudio2 = Get-Service WavesAudioService -ErrorAction SilentlyContinue
        if ($WaveAudio2.count -eq 1) {
        Stop-Service $WaveAudio2
        Write-Host Stopped $WaveAudio2.DisplayName
        Write-Host ""
    }
    #Disable audio device
    Write-Host "Disabling adapter..."
    Disable-PnpDevice "$HardwareID" -Confirm:$false -ErrorAction SilentlyContinue
    if ($Error.Count -gt 0) {
        Write-Host ""
        Write-Host -ForegroundColor Red "Issue disabling. Check that nothing besides the system is using sound and then rerun."
        SndVol.exe
        Write-Host ""
        timeout.exe /t 3
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
    timeout /t 3
    #Restart servies
    }
        Write-Host ""
        Write-Host Restarting services...
        Write-Host ""
    if ($Audio1.Count -eq 1) {
        Start-Service $Audio1
        Write-Host Started $Audio1.DisplayName
        Write-Host ""
    }
        if ($Audio2.Count -eq 1) {
        Start-Service $Audio2
        Write-Host Started $Audio2.DisplayName
        Write-Host ""
    }
        if ($WaveAudio1.Count -eq 1) {
        Start-Service $WaveAudio1
        Write-Host Started $WaveAudio1.DisplayName
        Write-Host ""
    }
        if ($WaveAudio2.count -eq 1) {
        Start-Service $WaveAudio2
        Write-Host Started $WaveAudio2.DisplayName
        Write-Host ""
    }
    Write-Host -ForegroundColor Green Done!
    timeout /t 5
    Exit
}
