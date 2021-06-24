# @Example $config['tmpdir'] = valPath -path $config['tmpdir']
Function ValPath {
    Param (
        [Parameter(Mandatory=$true)]  [String]$path,
        [Parameter(Mandatory=$false)] [Bool]$isDir = $true
    )

    $path = $path -replace "/", "\"

    $lastChar = $path.Substring($path.Length - 1)

    if($lastChar -NotLike "\" -And $isDir)
    {
        $path = "$($path)\"
    }

    return $path
}


# @Example printMsg -msg "Mon super message"  -backColor "black" -sharpColor "red" -textColor "blue"
Function printMsg {
    Param (
        [Parameter(Mandatory=$true)]  [String]$msg,
        [Parameter(Mandatory=$false)]  [String]$backColor = "black",
        [Parameter(Mandatory=$false)]  [String]$sharpColor = "Blue",
        [Parameter(Mandatory=$false)]  [String]$textColor = "Cyan"
    )

    $charCount = $msg.Length + 2

    for ($i = 1 ; $i -le $charCount ; $i++){$sharp += "#"}

    Write-Host ($sharp) -ForegroundColor $sharpColor -BackgroundColor $BackColor
    Write-Host (" $($msg) ") -ForegroundColor $textColor -BackgroundColor $BackColor
    Write-Host ("$($sharp)`n") -ForegroundColor $sharpColor -BackgroundColor $BackColor
}