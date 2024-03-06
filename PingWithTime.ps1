#Ping with time stamps
#Made for PS7!

$OutFolder = $Env:USERPROFILE + '\' + 'Downloads'
$PingCount = '99999999'

#--------

Clear-Host

Write-Host '
==========================
Ping test with time stamps
==========================
'

function Address {
    $Address = Read-Host -Prompt "Enter ip/domain to test"
    if ($Address.Length -EQ 0) {
        Address
    }
    $Address
}

function FormattedTime {
    $Time = Get-Date
    $Time = $Time.ToLongTimeString()
    $Time
}

$Address = Address
$OutFile = $OutFolder + '\' + $Address + '.txt'
$TestFile = Test-Path $OutFile
if ($TestFile -eq $true) {
    Write-Host ''
    $LASTEXITCODE = 0
    choice /m 'File already exists. Delete first?'
    Write-Host
    if (($LASTEXITCODE -ne 1) -and ($LASTEXITCODE -ne 2)) {
        Write-Host -ForegroundColor Red 'Error in selection
        '
        Pause
        Exit 1
    } elseif ($LASTEXITCODE -eq 1) {
        Remove-Item $OutFile -Force
    }
}

Test-Connection -Ping $Address -Count $PingCount -DontFragment -OutVariable Table | Select-Object * | Format-Table @{Name="Time";Expression={FormattedTime}},Ping,Address,Latency,Status -Wrap | Tee-Object -FilePath $OutFile -Append
