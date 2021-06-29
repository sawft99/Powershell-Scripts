#Made for PS7!
function Address {
    $global:Address = Read-Host -Prompt "Enter ip/domain to test"
    if ($global:Address.Length -EQ 0) {
        Address
    }
}
Address
function FormattedTime {
    $Var = Get-Date
    $TimeFinal = $Var.ToLongTimeString()
    $TimeFinal
}

Test-Connection -Ping $global:Address -Count 20 | Format-Table @{Name="Time";Expression={FormattedTime}},Ping,Address,Latency