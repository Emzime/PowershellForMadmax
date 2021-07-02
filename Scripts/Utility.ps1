# Intenationalization import
$UTlang = Import-LocalizedData -BaseDirectory "Scripts\lang"

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
        [Parameter(Mandatory=$true)]   [String]$msg,
        [Parameter(Mandatory=$false)]  [String]$msg2,
        [Parameter(Mandatory=$false)]  [String]$msg3,
        [Parameter(Mandatory=$false)]  [String]$backColor = "black",
        [Parameter(Mandatory=$false)]  [String]$sharpColor = "Green",
        [Parameter(Mandatory=$false)]  [String]$textColor = "Yellow",
        [Parameter(Mandatory=$false)]  [bool]$blu = $false,
        [Parameter(Mandatory=$false)]  [bool]$bld = $true
    )

    # Add back to line on Top or on down
    if($blu){$btlu = "`n"}
    if($bld){$btld = "`n"}

    # Condition
    if($msg1)
    {
        $charCount = ($msg.Length + 2) + ($msg2.Length) + ($msg3.Length)
    }
    elseif($msg2)
    {
        $charCount = ($msg.Length + 2) + ($msg2.Length + 1) + ($msg3.Length)
    }
    elseif($msg3)
    {
        $charCount = ($msg.Length + 2) + ($msg2.Length + 1) + ($msg3.Length + 1)
    }
    else
    {
        $charCount = ($msg.Length + 2) + ($msg2.Length) + ($msg3.Length)
    }

    # Count number of #
    for ($i = 1 ; $i -le $charCount ; $i++){$sharp += "#"}

    # Display message
    Write-Host ("$($btlu)$($sharp)") -ForegroundColor $sharpColor -BackgroundColor $BackColor
    Write-Host (" $($msg) $($msg2) $($msg3) ") -ForegroundColor $textColor -BackgroundColor $BackColor
    Write-Host ("$($sharp)$($btld)") -ForegroundColor $sharpColor -BackgroundColor $BackColor
}

# Verification and allocation of disk space
Function SelectDisk {

    # Set the default space requirement
    if(!($requiredSpace)){$requiredSpace = 102}

    # Display information about the space required
    PrintMsg -msg $UTlang.SpaceRequire -msg2 $requiredSpace -msg3 $UTlang.Gigaoctet

    # We make a loop to find the free space
    foreach ($_ in $config['finalDir'])
    {
        # Get letters from final disk with folder
        $deviceLetter = $_.Substring(0,1)

        # We query the selected hard drives
        $diskSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($deviceLetter):'" | Select-Object FreeSpace

        # Defines space in Gio
        $diskSpace = [int] [math]::Round($diskSpace.FreeSpace / 1073741824)

        # Check which disk is available
        if ($diskSpace -ge $requiredSpace)
        {
            # Takes a break
            start-sleep -s $smallTime

            # Display letter
            PrintMsg -msg $UTlang.TestSpaceDisk

            # Takes a break
            start-sleep -s $smallTime 

            # Display letter
            PrintMsg -msg $UTlang.FinaleDiskUsed -msg2 "$($deviceLetter):\"

            # Takes a break
            start-sleep -s $midTime 

            # Display available capacity
            PrintMsg -msg $UTlang.FreeSpaceRemaining -msg2 $diskSpace -msg3 $UTlang.Gigaoctet

            # Takes a break
            start-sleep -s $smallTime

            # Return hard disk letter
            return $_
        
            # Stop if space available
            break
        }
    }
}

# Launching process of moving the plots
Function MovePlots {
    Param(
        $newPlotLogName = [String]$newPlotLogName,
        $finalSelectDisk = [String]$finalSelectDisk
    )

    # Starts the move window if the process does not exist
    $startMovePlots = new-object System.Diagnostics.ProcessStartInfo
    $startMovePlots.FileName = "$pshome\powershell.exe"

    # Get plot name log
    $newPlotLogName = $config["logDir"] + "Moved_" + $newPlotLogName.Substring(11,$newPlotLogName.Length-11) + ".log"

    # Log creation if logs are enabled
    if($config["logsMoved"])
    {
        # Starts the creation of plots with logs (RESTE DES VARIABLES A AJOUTER TEMPDIR2 etc)
        $startMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle='MovePlots'; while ('$true') {robocopy $($config["tmpDir"]) $finalSelectDisk *.plot /unilog:'$newPlotLogName' /tee /mov; sleep $sleepTime}"

        # Display information
        PrintMsg -msg $UTlang.LogsInProgress -msg2 "$newPlotLogName" -blu $true

        # Takes a break
        start-sleep -s $smallTime

        # Starts the creation
        $processMovePlots = [Diagnostics.Process]::Start($startMovePlots)
    }
    else
    {
        # Starts the creation of plots without logs (RESTE DES VARIABLES A AJOUTER TEMPDIR2 etc)
        $startMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle='MovePlots'; while ('$true') {robocopy $($config["tmpDir"]) $finalSelectDisk *.plot /mov; sleep $sleepTime}"
        $processMovePlots = [Diagnostics.Process]::Start($startMovePlots)
    }

    # Takes a break
    start-sleep -s $smallTime

    # Display information
    PrintMsg -msg $UTlang.MovePlotInProgress -msg2 $UTlang.ProcessID -msg3 $processMovePlots.ID

    # Get process id
    return $processMovePlots.ID
}

# Launching the plot creation
function CreatePlots {

    # Set buckets3 if active
    if(!($config["buckets3"])){$config["buckets3"] = ""}

    # Log creation if logs are enabled
    if($config["logs"])
    {
        # Plot log name
        $newPlotLogName1 = $($config["logDir"]) + "Create_" + $dateTime + ".log"

        # Display information
        PrintMsg -msg $UTlang.LogsInProgress -msg2 "$newPlotLogName1"

        # Takes a break
        start-sleep -s $smallTime

        # Display information
        PrintMsg -msg $UTlang.LaunchCreatePlot

        # Takes a break
        start-sleep -s $smallTime

        # Starts the creation of plots with logs
        $processCreatePlots = ."$($config["chiaPlotterLoc"])\chia_plot.exe" --threads $config["threads"] --buckets $config["buckets"] --buckets3 $config["buckets3"] --tmpdir $config["tmpDir"] --tmpdir2 $config["tmpDir2"] --tmptoggle $config["tmpToggle"] --farmerkey $config["farmerKey"] --poolkey $config["poolKey"] --count 1 | tee "$newPlotLogName1" | Out-Default
  
        # Get log name
        $plotName = Get-Content -Path "$newPlotLogName1" | where { $_ -match "plot-k32-"}

        # Plot log name
        $newPlotLogName2 = $config["logDir"] + "Create_" + $plotName.Substring(11,$plotName.Length-11) + ".log"

        # Rename log with plot name
        $renameCreatedLog = Rename-Item -Path "$newPlotLogName1" -NewName "$newPlotLogName2"
    }
    else
    {
        # Takes a break
        start-sleep -s $smallTime

        # Starts the creation of plots without logs
        $processCreatePlots = ."$($config["chiaPlotterLoc"])\chia_plot.exe" --threads $config["threads"] --buckets $config["buckets"] --buckets3 $config["buckets3"] --tmpdir $config["tmpDir"] --tmpdir2 $config["tmpDir2"] --tmptoggle $config["tmpToggle"] --farmerkey $config["farmerKey"] --poolkey $config["poolKey"] --count 1 | Out-Default
    }

    # Get process id
    return $plotName
}

Function CreateFolder
{
    Param(
        [String]$folder
    )
    # Create tmpDir directory
    $newItem = New-Item -Path "$folder" -ItemType Container
    # Displays creation of the directory
    PrintMsg -msg $UTlang.TempDirCreated -msg2 "-> $folder"
    # Takes a break
    start-sleep -s $smallTime
}
