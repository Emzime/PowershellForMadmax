﻿# Intenationalization import
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

    # $path = $path -replace "\\", "\"

    return $path
}

# @Example PrintMsg -msg "Mon super message" -backColor "black" -sharpColor "red" -textColor "blue"
# @ Use  -blu $true to back line on top
# @ Use  -bld $false to stop back line on down
Function PrintMsg {
    Param (
        [Parameter(Mandatory=$true)]  [String]$msg,
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
    Param (
        [Object]$finalDir,
        [int]$requiredSpace,
        [int]$smallTime,
        [int]$midTime,
        [int]$bigTime
    )

    # Set the default space requirement
    if(!($requiredSpace)){$requiredSpace = 102}

    # Display information about the space required
    PrintMsg -msg $UTlang.SpaceRequire -msg2 $requiredSpace -msg3 $UTlang.Gigaoctet -blu $true

    # We make a loop to find the free space
    foreach ($_ in $finalDir)
    {
        # We query the selected hard drives
        $diskSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($_):'" | Select-Object FreeSpace

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
            start-sleep -s $midTime 

            # Display available capacity
            PrintMsg -msg $UTlang.FreeSpaceRemaining -msg2 $diskSpace -msg3 $UTlang.Gigaoctet

            # Takes a break
            start-sleep -s $smallTime 

            # Display letter
            PrintMsg -msg $UTlang.FinaleDiskUsed -msg2 "$($_):\"

            # Takes a break
            start-sleep -s $smallTime

            # Return hard disk letter
            return "$($_):\"
        
            # Stop if space available
            break
        }
    }
}

# Launching process of moving the plots
Function MovePlots {
    Param (
        [string]$tmpDir,
        [String]$logDir,
        [String]$finalDir,
        [String]$dateTime,
        [int]$sleepTime,
        [int]$smallTime,
        [int]$midTime,
        [int]$bigTime,
        [bool]$logsMoved
    )

    # Starts the move window if the process does not exist
    $startMovePlots = new-object System.Diagnostics.ProcessStartInfo
    $startMovePlots.FileName = "$pshome\powershell.exe"
    
    # Log creation if logs are enabled
    if($logsMoved)
    {
        # Starts the creation of plots with logs (RESTE DES VARIABLES A AJOUTER TEMPDIR2 etc)
        $startMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle='MovePlots'; while ('$true') {robocopy '$tmpDir' '$finalDir' *.plot /unilog:'$logDir\moved_log_$dateTime.log' /tee /mov; sleep $sleepTime}"
        $processMovePlots = [Diagnostics.Process]::Start($startMovePlots)

        # Display information
        PrintMsg -msg $UTlang.LogsInProgress -msg2 "$logDir\moved_log_$dateTime.log"
    }
    else
    {
        # Starts the creation of plots without logs (RESTE DES VARIABLES A AJOUTER TEMPDIR2 etc)
        $startMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle='MovePlots'; while ('$true') {robocopy '$tmpDir' '$finalDir' *.plot /mov; sleep $sleepTime}"
        $processMovePlots = [Diagnostics.Process]::Start($startMovePlots)
    }

    # Display information
    PrintMsg -msg $UTlang.MovePlotInProgress -msg2 $UTlang.ProcessID  -msg3 $processMovePlots.ID

    # Get process id
    return $processMovePlots.ID
}

# Launching the plot creation
function CreatePlots {
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
        [String]$dateTime,
        [String]$farmerKey,
        [String]$chiaPlotterLoc,
        [bool]$logs,
        [bool]$tmpToggle
    )

    # Options
    # Set buckets3 if active
    if($buckets3){$buckets3 = $buckets3}else{$buckets3 = ""}

    # Set tmpDir2 if active
    if($tmpDir2){$tmpDir2 = $tmpDir2}else{$tmpDir2 = $tmpDir}

    # Set tmptoggle if active and tmpDir2 ative
    if(($tmpDir2) -AND (!($tmpDir2 -eq $tmpDir)) -AND ($tmpToggle -eq $true)){
        $tmpToggle = $True
    }else{
        $tmpToggle = $false

        # Display information
        PrintMsg -msg $UTlang.tmpToggleDeactivate

        # Takes a break
        start-sleep -s $midTime
    }

    # Log creation if logs are enabled
    if($logs)
    {
        # Display information
        PrintMsg -msg $UTlang.LogsInProgress -msg2 "$logDir\created_log_$dateTime.log"

        # Takes a break
        start-sleep -s $smallTime

        # Display information
        PrintMsg -msg $UTlang.LaunchCreatePlot

        # Takes a break
        start-sleep -s $smallTime

        # Starts the creation of plots with logs (RESTE DES VARIABLES A AJOUTER TEMPDIR2 etc)
        $processCreatePlots = .$chiaPlotterLoc\chia_plot.exe --threads $threads --buckets $buckets --buckets3 $buckets3 --tmpdir $tmpDir --tmpdir2 $tmpDir2 --tmptoggle $tmpToggle --farmerkey $farmerKey --poolkey $poolKey --count 1 | tee "$logDir\created_log_$dateTime.log" | Out-Default
    }
    else
    {
        # Takes a break
        start-sleep -s $smallTime

        # Starts the creation of plots without logs (RESTE DES VARIABLES A AJOUTER TEMPDIR2 etc)
        $processCreatePlots = .$chiaPlotterLoc\chia_plot.exe --threads $threads --buckets $buckets --buckets3 $buckets3 --tmpdir $tmpDir --tmpdir2 $tmpDir2 --tmptoggle $tmpToggle --farmerkey $farmerKey --poolkey $poolKey --count 1 | Out-Default
    }

    # Takes a break
    start-sleep -s $smallTime

    # Display information
    PrintMsg -msg $UTlang.CreatePlotInProgress -msg2 $UTlang.ProcessID  -msg3 $processCreatePlots.ID

    # Get process id
    return $processCreatePlots.ID
}

Function CheckPath
{
    [CmdletBinding()]
    Param (
        [String]$logDir,
        [string]$tmpDir,
        [string]$tmpDir2,
        [String]$chiaPlotterLoc
    )

    # Set default tmpDir2 directory
    if($tmpDir2){$tmpDir2 = $tmpDir2}else{$tmpDir2 = $tmpDir}

    # Check if chiaPlotterLoc path exists and apply ValPath
    if(!($chiaPlotterLoc) -or !(Test-Path -Path "$chiaPlotterLoc"))
    {
        PrintMsg -msg $UTlang.PathTempNotFound -msg2 "-> chiaPlotterLoc" -textColor "Red" -backColor "Black" -sharpColor "Red"
        PrintMsg -msg $UTlang.ProcessMoveClosedImpossibleEnter -textColor "Red" -backColor "Black" -sharpColor "Red"
        $input = Read-Host
        exit
    }
    else 
    {
        # Apply ValPath
        $config["chiaPlotterLoc"] = ValPath -path $chiaPlotterLoc
        # Displays creation of the directory
        PrintMsg -msg $UTlang.ValPathApply -msg2 "chiaPlotterLoc"
    }
     
    # Takes a break
    start-sleep -s $smallTime

    # Check if tmpDir path exists and apply ValPath
    if(!($tmpDir))
    {
        PrintMsg -msg $UTlang.PathTempNotFound -msg2 "-> tmpDir" -textColor "Red" -backColor "Black" -sharpColor "Red"
        PrintMsg -msg $UTlang.ProcessMoveClosedImpossibleEnter -textColor "Red" -backColor "Black" -sharpColor "Red"
        $input = Read-Host
        exit
    }
    elseif (!(Test-Path -Path "$tmpDir"))
    {
        # Create tmpDir directory
        $newItem = New-Item -Path "$tmpDir" -ItemType Container
        # Displays creation of the directory
        PrintMsg -msg $UTlang.TempDirCreated -msg2 "-> $tmpDir"     
        # Takes a break
        start-sleep -s $smallTime
        # Apply ValPath
        $config["tmpDir"] = ValPath -path $tmpDir
        # Displays creation of the directory
        PrintMsg -msg $UTlang.ValPathApply -msg2 "tmpDir"
    }
    else 
    {
        # Apply ValPath
        $config["tmpDir"] = ValPath -path $tmpDir
        # Displays creation of the directory
        PrintMsg -msg $UTlang.ValPathApply -msg2 "tmpDir"
    }
     
    # Takes a break
    start-sleep -s $smallTime

    # Check if logDir path exists and apply ValPath
    if(!($logDir))
    {
        # Create log directory
        $newItem = New-Item -Path "$logDir" -ItemType Container
        # Displays creation of the directory
        PrintMsg -msg $UTlang.TempDirCreated -msg2 "-> "$logDir    
        # Takes a break
        start-sleep -s $smallTime
        # Apply ValPath
        $config["logDir"] = ValPath -path $logDir
        # Displays creation of the directory
        PrintMsg -msg $UTlang.ValPathApply -msg2 "logDir"
    }
    elseif (!(Test-Path -Path $logDir))
    {
        # Create log directory
        $newItem = New-Item -Path "$logDir" -ItemType Container
        # Displays creation of the directory
        PrintMsg -msg $UTlang.TempDirCreated -msg2 "-> "$logDir     
        # Takes a break
        start-sleep -s $smallTime
        # Apply ValPath
        $config["logDir"] = ValPath -path $logDir
        # Displays creation of the directory
        PrintMsg -msg $UTlang.ValPathApply -msg2 "logDir"
    }
    else 
    {
        # Apply ValPath
        $results = ValPath -path $logDir
        # Displays creation of the directory
        PrintMsg -msg $UTlang.ValPathApply -msg2 "logDir"
    }
     
    # Takes a break
    start-sleep -s $smallTime

    # Check if tmpDir2 path exists and apply ValPath
    if(!($tmpDir2))
    {
        PrintMsg -msg $UTlang.PathTempNotFound -msg2 "-> $tmpDir2" -textColor "Red" -backColor "Black" -sharpColor "Red"
        PrintMsg -msg $UTlang.ProcessMoveClosedImpossibleEnter -textColor "Red" -backColor "Black" -sharpColor "Red"
        $input = Read-Host
        exit
    }
    elseif (!(Test-Path -Path "$tmpDir2"))
    {
        # Create tmpDir directory
        $newItem = New-Item -Path "$tmpDir2" -ItemType Container
        # Displays creation of the directory
        PrintMsg -msg $UTlang.TempDirCreated -msg2 "-> $tmpDir2"     
        # Takes a break
        start-sleep -s $smallTime
        # Apply ValPath
        $config["tmpDir2"] = ValPath -path $tmpDir2
        # Displays creation of the directory
        PrintMsg -msg $UTlang.ValPathApply -msg2 "tmpDir2"
    }
    else 
    {
        # Apply ValPath
        $config["tmpDir2"] = ValPath -path $tmpDir2
        # Displays creation of the directory
        PrintMsg -msg $UTlang.ValPathApply -msg2 "tmpDir2"
    }

    # Takes a break
    start-sleep -s $smallTime
}