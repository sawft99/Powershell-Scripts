#Ping with time stamps
#Made for PS7!

#Make sure not to have a '\' at the end when passing a path
$OutFolder = 'C:\Users\Example\Downloads\Results' #$args[0]
#0 is unlimited
$PingCount = '0' # $args[1]
#Set console width. Helps prevent wraping or incomplete output
[console]::BufferWidth = 140

#--------

$Error.Clear()
Clear-Host

Write-Host '
==========================
Ping test with time stamps
==========================
'

function Address {
    $Address = $null
    while ($null -eq $Address) {
        try {
            $Error.Clear()
            $InputAddress = Read-Host -Prompt "Enter IP address to test"
            $Address = [System.Net.IPAddress]::Parse($InputAddress)
        } catch {
            Write-Host -ForegroundColor Red 'Enter a proper IP address'
            $Address = $null
        }
    }
    return $Address
}

function FormattedTime {
    $Time = Get-Date
    $Time = $Time.ToLongTimeString()
    $Time
}

function OutFile {
    $OutFile = $OutFolder + '\' + $Address + '.txt'
    if (Test-Path $OutFile) {
        $Error.Clear()
        $DeleteChoices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Delete the file"),
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not delete the file")
        )
        $DeleteChoiceCaption = 'File already exists. Not deleting will cause the file to be appended. Delete file?'
        $DeleteChoiceMessage = $Null
        $Result = $Host.UI.PromptForChoice($DeleteChoiceCaption, $DeleteChoiceMessage, $DeleteChoices, -1)
        Write-Host ''
        if (($Result -ne 0) -and ($Result -ne 1)) {
            Write-Host -ForegroundColor Red 'Error in selection
            '
            exit 1
        } elseif ($Result -eq 0) {
            Remove-Item $OutFile -Force
            if (Test-Path $OutFile) {
                Write-Host -ForegroundColor Red 'Failed to remove file'
                exit 1
            } else {
                Write-Host 'File deleted'
            }
        }
    }
    $OutFile
}

function Ping {
    if ($PingCount -le 0) {
        Test-Connection -Ping $Address -Repeat -DontFragment -OutVariable Table | Select-Object * | Format-Table @{Name="Time";Expression={FormattedTime}},Ping,Address,Latency,Status -Expand Both -Wrap | Tee-Object -FilePath $OutFile -Append
    } else {
        Test-Connection -Ping $Address -Count $PingCount -DontFragment -OutVariable Table | Select-Object * | Format-Table @{Name="Time";Expression={FormattedTime}},Ping,Address,Latency,Status -Expand Both -Wrap | Tee-Object -FilePath $OutFile -Append
    }
}

#------------

$Address = Address
$OutFile = OutFile

Ping
