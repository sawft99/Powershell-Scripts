#Get all Properties and Methods available in class
#If on PS7 change Get-WMIObject to 'Get-CimInstance'
#List all Namespaces in Root\ assuming you are working with root

$PSversion = $PSVersionTable.PSVersion.Major

function ConfirmOut {
    Write-Host "
Options:

1. Yes
2. No
"
    $global:ConfirmOut = Read-Host -Prompt "Output results to file?"
    if (!($global:ConfirmOut -in 1..2)) {
        Write-Warning "Pick a valid option"
        ConfirmOut
    }
    if ($global:ConfirmOut -eq 1) {
        $global:OutLocation = Read-Host -Prompt "Enter folder to store results"
        if (!(Test-Path $global:OutLocation)) {
            Write-Warning "Folder does not exist"
            ConfirmOut
        }
    }
}

if ($PSversion -eq 5) {
    Write-Host ""
    $List1 = Get-WMIObject -Namespace root -Class __Namespace | Select-object -Property Name | Sort-Object -Property Name
    Write-host "Available Root namespaces:"
    Write-host ""
    $List1.Name
    Write-Host ""

    do {
        $null = $Namespace1Error
        $Namespace1 = Read-Host "Explore which namespace? Default root\cimv2"
        if ($Namespace1.length -eq 0) {
            $Namespace1 = "root\cimv2"
        }
        $Namespace2 = Get-WMIObject -Namespace $Namespace1 -List -ErrorVariable NameSpace1Error -ErrorAction SilentlyContinue | Sort-Object -Property Name
        if ($Namespace1Error.capacity -ne 0) {
            Write-Warning "Invalid namespace"
        }
    }
    while ($Namespace1Error.capacity -ne 0)
    
    ConfirmOut

    switch ($global:ConfirmOut) {
        1 {
            $Namespace2
            Write-Host
            Write-Host "Namespace is $Namespace1"
            Write-Output "Namespace is $Namespace1" | Out-File $OutLocation\Classes.txt
            $Namespace2 | Out-File $global:OutLocation\Classes.txt -Append
        }
        2 {
            $Namespace2
        }
    }

    do {
        $null = $Class1Error
        Write-Host ""
        Write-Host "Current namespace is $Namespace1"
        Write-Host ""
        $WMIObject = Read-Host -Prompt "Which Class to search"
        $Class1 = Get-WMIObject -Namespace $Namespace1 -Class $WMIObject -ErrorVariable Class1Error -ErrorAction SilentlyContinue
        if (!($null -eq $Class1Error.Capacity -or $Class1Error.Capacity -eq 0)) {
            Write-Warning "Invalid class"
        }
        else {
            $Class1 = Get-WMIObject -Namespace $Namespace1 -Class $WMIObject -List -ErrorVariable Class1Error -ErrorAction SilentlyContinue
        }
    }
    while ($Class1Error.Capacity -ne 0)

    switch ($global:ConfirmOut) {
        1 {
            Write-Host ""
            Write-Host "All Properties"
            Write-Host ""
            Write-Host Namespace is $Namespace1 and Class is $Class1.Name
            Write-Output "Namespace is $Namespace1 and Class is" $Class1.Name | Out-File $OutLocation\Properties.txt
            if ($Class1.Properties.length -eq 0 -or $null -eq $Class1.Properties.length) {
                Write-Output "" | Out-File $OutLocation\Properties.txt -Append
                Write-Host ""
                Write-Warning "No Properties in this class"
                Write-Output "No Properties in this class" | Out-File $global:OutLocation\Properties.txt -Append
                Write-Host ""
            }
            else {
                Write-Host ""
                Write-Output "Namespace is $Namespace1 and Class is" $Class1.Name | Out-File $OutLocation\Properties.txt
                $Class1.Properties | Sort-Object -Property Name | Format-Table -Property Name,Value
                $Class1.Properties | Sort-Object -Property Name | Format-Table -Property Name,Value | Out-File $global:OutLocation\Properties.txt -Append
            }
            Write-Host "Methods"
            Write-Host ""
            Write-Host Namespace is $Namespace1 and Class is $Class1.Name
            Write-Host ""
            Write-Output "Namespace is $Namespace1 and Class is" $Class1.Name | Out-File $OutLocation\Methods.txt
            Write-Output "" | Out-File $OutLocation\Methods.txt -Append
            if ($Class1.Methods.length -eq 0 -or $null -eq $Class1.Methods.length) {
                Write-Warning "No Methods in this class"
                Write-Output "No Methods in this class" | Out-File $global:OutLocation\Methods.txt -Append
                Write-Host "" 
            }
            else {
                $Class1.Methods | Sort-Object -Property Name | Format-Table -Property Name,Value
                $Class1.Methods | Sort-Object -Property Name | Format-Table -Property Name,Value | Out-File $global:OutLocation\Methods.txt -Append
            }
        }
        2 {
            Write-Host ""
            Write-Host "All Properties"
            Write-Host ""
            Write-Host "Namespace is $Namespace1 and Class is" $Class1.Name
            Write-Host ""
            if ($Class1.Properties.length -eq 0 -or $null -eq $Class1.Properties.length) {
                Write-Warning "No Properties in this class"
                Write-Host ""
        }
            else {
                $Class1.Properties | Sort-Object -Property Name | Format-Table -Property Name,Value
            }
            Write-Host "Methods"
            Write-Host ""
            Write-Host "Namespace is $Namespace1 and Class is" $Class1.Name
            Write-Host ""
            if ($Class1.Methods.length -eq 0 -or $null -eq $Class1.Methods.length) {
                Write-Warning "No Methods in this class"
                Write-Host "" 
            }
            else {
                $Class1.Methods | Sort-Object -Property Name | Format-Table -Property Name,Value
            }
        }
    }
}

if ($PSversion -gt 5) {
    Write-Host ""
    $List1 = Get-CimInstance -Namespace root -ClassName __Namespace | Select-object -Property Name | Sort-Object -Property Name
    Write-host "Available Root namespaces:"
    Write-host ""
    $List1.Name
    Write-Host ""

    do {
        $null = $Namespace1Error
        $Namespace1 = Read-Host "Explore which namespace? Default root\cimv2"
        if ($Namespace1.length -eq 0) {
            $Namespace1 = "root\cimv2"
        }
        $Namespace2 = Get-CimInstance -Namespace $Namespace1 -ClassName __Namespace -ErrorVariable NameSpace1Error -ErrorAction SilentlyContinue | Sort-Object -Property Name
        if ($Namespace1Error.capacity -ne 0) {
            Write-Warning "Invalid namespace"
        }
    }
    while ($Namespace1Error.capacity -ne 0)

    ConfirmOut

    switch ($global:ConfirmOut) {
        1 {
            $Namespace2.Name
            Write-Host
            Write-Host "Namespace is $Namespace1"
            Write-Host
            Write-Output "Namespace is $Namespace1" | Out-File $OutLocation\Classes.txt
            $Namespace2 | Out-File $global:OutLocation\Classes.txt -Append
        }
        2 {
            Write-Host
            Write-Host "Namespace is $Namespace1"
            Write-Host
            $Namespace2.Name
        }
    }

    do {
        $null = $Class1Error
        Write-Host ""
        $WMIObject = Read-Host -Prompt "Which class to search"
        $Class1 = Get-CimInstance -Namespace $Namespace1 -Class $WMIObject -ErrorVariable Class1Error -ErrorAction SilentlyContinue
        if (!($null -eq $Class1Error.Capacity -or $Class1Error.Capacity -eq 0)) {
            Write-Warning "Invalid class"
        }
        else {
            $Class1 = Get-CimInstance -Namespace $Namespace1\$WMIObject -Class __Namespace  -ErrorVariable Class1Error -ErrorAction SilentlyContinue
        }
    }
    while ($Class1Error.Capacity -ne 0)

    switch ($global:ConfirmOut) {
        1 {
            Write-Host ""
            Write-Host "All Properties"
            Write-Host ""
            Write-Host Namespace is $Namespace1 and Class is $Class1.Name
            Write-Output "Namespace is $Namespace1 and Class is" $Class1.Name | Out-File $OutLocation\Properties.txt
            if ($Class1.Properties.length -eq 0 -or $null -eq $Class1.Properties.length) {
                Write-Output "" | Out-File $OutLocation\Properties.txt -Append
                Write-Host ""
                Write-Warning "No Properties in this class"
                Write-Output "No Properties in this class" | Out-File $global:OutLocation\Properties.txt -Append
                Write-Host ""
            }
            else {
                Write-Host ""
                Write-Output "Namespace is $Namespace1 and Class is" $Class1.Name | Out-File $OutLocation\Properties.txt
                $Class1.Properties | Sort-Object -Property Name | Format-Table -Property Name,Value
                $Class1.Properties | Sort-Object -Property Name | Format-Table -Property Name,Value | Out-File $global:OutLocation\Properties.txt -Append
            }
            Write-Host "Methods"
            Write-Host ""
            Write-Host Namespace is $Namespace1 and Class is $Class1.Name
            Write-Host ""
            Write-Output "Namespace is $Namespace1 and Class is" $Class1.Name | Out-File $OutLocation\Methods.txt
            Write-Output "" | Out-File $OutLocation\Methods.txt -Append
            if ($Class1.Methods.length -eq 0 -or $null -eq $Class1.Methods.length) {
                Write-Warning "No Methods in this class"
                Write-Output "No Methods in this class" | Out-File $global:OutLocation\Methods.txt -Append
                Write-Host "" 
            }
            else {
                $Class1.Methods | Sort-Object -Property Name | Format-Table -Property Name,Value
                $Class1.Methods | Sort-Object -Property Name | Format-Table -Property Name,Value | Out-File $global:OutLocation\Methods.txt -Append
            }
        }
        2 {
            Write-Host ""
            Write-Host "All Properties"
            Write-Host ""
            Write-Host "Namespace is $Namespace1 and Class is" $Class1.Name
            Write-Host ""
            if ($Class1.Properties.length -eq 0 -or $null -eq $Class1.Properties.length) {
                Write-Warning "No Properties in this class"
                Write-Host ""
            }
            else {
                $Class1.Properties | Sort-Object -Property Name | Format-Table -Property Name,Value
            }
            Write-Host "Methods"
            Write-Host ""
            Write-Host "Namespace is $Namespace1 and Class is" $Class1.Name
            Write-Host ""
            if ($Class1.Methods.length -eq 0 -or $null -eq $Class1.Methods.length) {
                Write-Warning "No Methods in this class"
                Write-Host "" 
            }
            else {
                $Class1.Methods | Sort-Object -Property Name | Format-Table -Property Name,Value
            }
        }
    }
}