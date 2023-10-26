#A demo of the Collatz Conjecture Theory
#If x is odd apply:  3x + 1
#If x is even apply: x/2
#Repeat and you will always eventually end up with '1'

$x = 527

#Premade variables
$Odds = @(1,3,5,7,9)
$Evens = @(0,2,4,6,8)

Clear-Host

function Loop {
    $i = 1
    do {
        $LastNum = $x.ToString()[$x.ToString().Length - 1]
        $LastNum = $LastNum.ToString()
        if ($LastNum -in $Odds) {
            $x = (3 * $x) + 1
            $x = $x -as [decimal]
        } elseif ($LastNum -in $Evens) {
            $x = $x/2
            $x = $x -as [decimal]
        }
        Write-Host Step $i': '$x  
        $i++
    } until ($x -eq 1)
}

Loop
