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

# @Example PrintMsg -msg "Mon super message"  -backColor "black" -sharpColor "red" -textColor "blue"
# @ User  -blu $true to back line on top
# @ User  -bld $false to stop back line on down
Function PrintMsg {
    Param (
        [Parameter(Mandatory=$true)]  [String]$msg,
        [Parameter(Mandatory=$false)]  [String]$backColor = "black",
        [Parameter(Mandatory=$false)]  [String]$sharpColor = "Blue",
        [Parameter(Mandatory=$false)]  [String]$textColor = "Green",
        [Parameter(Mandatory=$false)]  [bool]$blu = $false,
        [Parameter(Mandatory=$false)]  [bool]$bld = $true
    )
    
    if($blu){$btlu = "`n"}
    if($bld){$btld = "`n"}

    $charCount = $msg.Length + 2

    for ($i = 1 ; $i -le $charCount ; $i++){$sharp += "#"}

    Write-Host ("$($btlu)$($sharp)") -ForegroundColor $sharpColor -BackgroundColor $BackColor
    Write-Host (" $($msg) ") -ForegroundColor $textColor -BackgroundColor $BackColor
    Write-Host ("$($sharp)$($btld)") -ForegroundColor $sharpColor -BackgroundColor $BackColor
}

# Verification and allocation of disk space
Function SelectDisk
{
    Param (
        [Object]$finaldir,
        [int]$smallTime,
        [int]$bigTime
    )
    
    # Check if CopyPlots process is running
    $ProcessCopyPlots = (Get-Process -NAME "CopyPlots" -Ea SilentlyContinue)

    # Defines space required
    If (!($ProcessCopyPlots -eq $null)){$RequiredSpace = 204}else{$RequiredSpace = 102}

    # Displays information about the space required
    PrintMsg -msg "Note: the space requirement is $RequiredSpace Go" -blu $true

    # Pausing
    start-sleep -s $smallTime
    
    foreach ($_ in $finaldir)
    {
        # we query the selected hard drives
        $diskSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($_):'" | Select-Object FreeSpace

        # Defines space in Gio
        $diskSpace = [int] [math]::Round($diskSpace.FreeSpace / 1073741824)

        # Check which disk is available
        if ($diskSpace -ge $RequiredSpace)
        {    
            # Displays letter and available capacity
            PrintMsg -msg "Final disk used $($_):\ -> Free space remaining $diskSpace Go"

            # Return hard disk letter
            return "$($_):\"
        
            # Stop if space available
            break
        }
    }
}

# Launching process of moving the plots
Function MovePlots
{
    Param (
        [string]$tmpdir,
        [String]$finaldir,
        [int]$sleepTime,
        [int]$smallTime,
        [int]$bigTime
    )

    # Starts the move window if the process does not exist
    $StartMovePlots = new-object System.Diagnostics.ProcessStartInfo
    $StartMovePlots.FileName = "$pshome\powershell.exe"
    $StartMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle=`'MovePlots`'; while ('$true') {robocopy $tmpdir $finaldir *.plot /mov; sleep $sleepTime}"

    # Displays information
    PrintMsg -msg "MovePlots process in progress..."

    # Takes a break
    start-sleep -s $smallTime

    # Starts the process
    $ProcessMovePlots = [Diagnostics.Process]::Start($StartMovePlots)
}

# Launching the plot creation
function CreatePlots
{
    Param (
        [Int]$bigTime,
        [Int]$threads,
        [Int]$buckets,
        [Int]$buckets3,
        [Int]$smallTime,
        [String]$logDir,
        [string]$tmpdir,
        [String]$poolkey,
        [string]$tmpdir2,
        [String]$finaldir,
        [String]$farmerkey,
        [String]$chiaPlotterLoc,
        [bool]$logs,
        [bool]$tmptoggle
    )
    
    # Displays information
    PrintMsg -msg "CreatePlots process in progress..."

    # Takes a break
    start-sleep -s $smallTime

    # Starts the creation of plots 
    .$chiaPlotterLoc\chia_plot.exe --threads $threads --buckets $buckets --tmpdir $tmpdir --farmerkey $farmerkey --poolkey $poolkey --count 1
}