# @Example $config['tmpDir'] = valPath -path $config['tmpDir']
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

# @Example PrintMsg -msg "Mon super message" -backColor "black" -sharpColor "red" -textColor "blue"
# @ Use  -blu $true to back line on top
# @ Use  -bld $false to stop back line on down
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
        [Object]$finalDir,
        [int]$smallTime,
        [int]$midTime,
        [int]$bigTime
    )
    
    # Check if CopyPlots process is running
    $processCopyPlots = (Get-Process -NAME "CopyPlots" -erroraction "silentlycontinue")

    # Defines space required
    If (!($processCopyPlots -eq $null)){$requiredSpace = 204}else{$requiredSpace = 102}

    # Displays information about the space required
    PrintMsg -msg "Note: the space requirement is $requiredSpace Go" -blu $true

    # Takes a break
    start-sleep -s $smallTime
    
    foreach ($_ in $finalDir)
    {
        # we query the selected hard drives
        $diskSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($_):'" | Select-Object FreeSpace

        # Defines space in Gio
        $diskSpace = [int] [math]::Round($diskSpace.FreeSpace / 1073741824)

        # Check which disk is available
        if ($diskSpace -ge $requiredSpace)
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
        [string]$tmpDir,
        [String]$finalDir,
        [int]$sleepTime,
        [int]$smallTime,
        [int]$midTime,
        [int]$bigTime
    )

    # Starts the move window if the process does not exist
    $startMovePlots = new-object System.Diagnostics.ProcessStartInfo
    $startMovePlots.FileName = "$pshome\powershell.exe"
    $startMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle='MovePlots'; while ('$true') {robocopy $tmpDir $finalDir *.plot /mov; sleep $sleepTime}"

    # Displays information
    PrintMsg -msg "MovePlots process in progress..."

    # Takes a break
    start-sleep -s $smallTime

    # Starts the process
    $processMovePlots = [Diagnostics.Process]::Start($startMovePlots)

    # Get process id
    $movePlotsID = $processMovePlots.ID
    return $movePlotsID
}

# Launching the plot creation
function CreatePlots
{
    Param (
        [int]$midTime,
        [Int]$bigTime,
        [Int]$threads,
        [Int]$buckets,
        [Int]$buckets3,
        [Int]$smallTime,
        [String]$logDir,
        [string]$tmpDir,
        [String]$poolKey,
        [string]$tmpDir2,
        [String]$finalDir,
        [String]$farmerKey,
        [String]$chiaPlotterLoc,
        [bool]$logs,
        [bool]$tmpToggle
    )
    
    # Displays information
    PrintMsg -msg "CreatePlots process in progress..."

    # Takes a break
    start-sleep -s $smallTime

    # Logs
    if($logs)
    {
        $writeLog = WriteLog
        $logOn = "| tee $writeLog"
    }
    else {
        $logOn = ""
    }

    # Starts the creation of plots 
    $creating = .$chiaPlotterLoc\chia_plot.exe --threads $threads --buckets $buckets --tmpdir $tmpDir --farmerkey $farmerKey --poolkey $poolKey --count 1 $logOn
        
    return $creating
}

# Logs (A REVOIR NE FONCTIONNE PAS)
Function WriteLog
{
    # Launch in admin mode if logs are enabled
    if($config["logs"])
    {
        # Get datetime
        if($PSCulture -eq "fr_FR") { $dateTime = $((get-date).ToLocalTime()).ToString("dd-MM-yyyy HH'h'mm'm'ss") }else{ $dateTime = $((get-date).ToLocalTime()).ToString("yyyy-MM-dd hh'h'mm'm'ss") }
        # Log directorie        
        $logsPath = $config["logDir"]
        # Check if log directorie is ok
        $testLogPath = Test-Path "$logsPath"
        # Log name
        $logFile = "$logsPath\Plot_$dateTime.log"
        # Log content
        $logMessage = "$dateTime"
        # Checks if logs are enabled
        if($testLogPath)
        {
            # Add content to log file
            Add-content $logFile -value $logMessage
        }
        else
        {
            # Create log repertorie if not exists
            New-Item -Path $logsPath -ItemType Container
            # Add content to log file
            Add-content $logFile -value $logMessage
        }
    }
}