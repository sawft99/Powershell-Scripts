#ROT encryption rotation
#Numbers and symbols are allowed but not rotated in any way
$Alphabet = @("A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z")
$Alphabet = $Alphabet.split(",")
#You can change the number of rotations to something other than the traditional 13
$RotRotation = 13

Clear-Host

Function GetMessage {
    Write-Host ""
    $Message = Read-Host -Prompt "Enter message that you want to encrypt or decrypt"
    $Message = $Message.ToUpper()
    $MessageSplit = $Message -split ""
    $MessageSplit = $MessageSplit | Select-Object -Skip 1
    $MessageSplit = $MessageSplit | Select-Object -SkipLast 1
    $MessageSplit
    return
}

Function Encryption {
    $NewMessage = @()
    Foreach ($Letter in $Message) {
        $LetterIndex = $Alphabet.IndexOf($Letter)
        if (($Letter -notin 0..9) -and ($Letter -notin $Alphabet)) {
            $NewLetter = $Letter
            $NewMessage += $NewLetter
            continue
        }
        if ($Letter -match " ") {
            $NewLetter = " "
            $NewMessage += $NewLetter
            continue
        }
        if ($Letter -in 0..9) {
            $NewLetter = $Letter
            $NewMessage += $NewLetter
            continue
        }
        if (($LetterIndex + $RotRotation) -gt 26) {
            $OverLetterIndex = ($LetterIndex + $RotRotation) - 26
            $NewLetter = $Alphabet[$OverLetterIndex]
            $NewMessage += $NewLetter
        } else {
            $NewLetter = $Alphabet[$LetterIndex + $RotRotation]
            $NewMessage += $NewLetter
        }
    }
    $NewMessage = $NewMessage -join ""
    $NewMessage
    return    
}

Function Decryption {
    $NewMessage = @()
    Foreach ($Letter in $Message) {
        $LetterIndex = $Alphabet.IndexOf($Letter)
        if (($Letter -notin 0..9) -and ($Letter -notin $Alphabet)) {
            $NewLetter = $Letter
            $NewMessage += $NewLetter
            continue
        }
        if ($Letter -match " ") {
            $NewLetter = " "
            $NewMessage += $NewLetter
            continue
        }
        if ($Letter -in 0..9) {
            $NewLetter = $Letter
            $NewMessage += $NewLetter
            continue
        }
        if (($LetterIndex - $RotRotation) -lt 0) {
            $OverLetterIndex = ($LetterIndex - $RotRotation) + 26
            $NewLetter = $Alphabet[$OverLetterIndex]
            $NewMessage += $NewLetter
        } else {
            $NewLetter = $Alphabet[$LetterIndex - $RotRotation]
            $NewMessage += $NewLetter
        }
    }
    $NewMessage = $NewMessage -join ""
    $NewMessage
    return    
}

Function AskOp {
    do {
        Clear-Host
    Write-Host ""
        $Op = Read-Host -Prompt "Select option 1 or 2:

1. Encrypt
2. Decrypt

Option"
if ($Op -ne 1 -and $Op -ne 2) {
    Write-Host ""
    Write-Host -ForegroundColor Red "Type '1' or '2'"
    Write-Host
    Pause
}
    } until ($Op -eq 1 -or $Op -eq 2)
    $Op
    return
}

$Op = AskOp

if ($Op -eq 1) {
    $Message = GetMessage
    $NewMessage = Encryption
    Write-Host ""
    $NewMessage
    Write-Host ""
}

if ($Op -eq 2) {
    $Message = GetMessage
    $OriginalMessage = Decryption
    Write-Host ""
    $OriginalMessage
    Write-Host ""
}