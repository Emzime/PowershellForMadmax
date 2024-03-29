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
    if($lastChar -NotLike "\" -And $isDir){$path = "$($path)\"}
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

        if(Test-Path -Path "$($deviceLetter):")
        {
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
                start-sleep -s $smallTime

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
        else
        {
            # Display letter
            PrintMsg -msg $UTlang.DiskNotExist -msg2 "$($deviceLetter):\" -msg3 $UTlang.DiskNotExist2 -textColor "Red" -backColor "Black" -sharpColor "Red"
            $input = Read-Host
            break
        }
    }
}

# Launching process of moving the plots
Function MovePlots {
    Param(
        [String]$newPlotLogName,
        [String]$finalSelectDisk
    )

    # Starts the move window if the process does not exist
    $startMovePlots = new-object System.Diagnostics.ProcessStartInfo
    $startMovePlots.FileName = "$pshome\powershell.exe"

    # Get plot path
    $newPlotNamePath = "$finalSelectDisk$newPlotLogName"

    # Get plot name
    $newPlotName = $newPlotLogName.Substring(0, $newPlotLogName.Length-9)

    # Log creation if logs are enabled
    if($config["logsMoved"])
    {
        # Get plot name log
        $newPlotLogName = $config["logDir"] + "Moved_" + $newPlotName + ".log"

        # Starts the creation of plots with logs
        $startMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle='MovePlots'; robocopy $($config["tmpDir"]) $finalSelectDisk *.plotMove /unilog:'$newPlotLogName' /tee /mov; rename-item -path '$newPlotNamePath' -NewName '$newPlotName.plot'; exit"

        # Display information
        PrintMsg -msg $UTlang.LogsInProgress -msg2 "$newPlotLogName" -blu $true

        # Takes a break
        start-sleep -s $smallTime

        # Starts the creation
        $processMovePlots = [Diagnostics.Process]::Start($startMovePlots)
    }
    else
    {
        # Starts the creation of plots without logs
        $startMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle='MovePlots'; robocopy $($config["tmpDir"]) $finalSelectDisk *.plotMove /mov; rename-item -path '$newPlotNamePath' -NewName '$newPlotName.plot'; exit"

        # Starts the creation
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
    if(!($config["buckets3"])){$config["buckets3"] = $config["buckets"]}

    # Starts the creation of plots without logs
    if(!([string]::IsNullOrEmpty($config["poolContract"])))
    {
        $processCreatePlots = ."$($config["chiaPlotterLoc"])\chia_plot.exe" --threads $config["threads"] --buckets $config["buckets"] --buckets3 $config["buckets3"] --tmpdir $config["tmpDir"] --tmpdir2 $config["tmpDir2"] --tmptoggle $config["tmpToggle"] --farmerkey $config["farmerKey"] --contract $($config["poolContract"]) --count 1 | Tee-Object -Variable plotLog | Out-Default
    }
    else
    {
        $processCreatePlots = ."$($config["chiaPlotterLoc"])\chia_plot.exe" --threads $config["threads"] --buckets $config["buckets"] --buckets3 $config["buckets3"] --tmpdir $config["tmpDir"] --tmpdir2 $config["tmpDir2"] --tmptoggle $config["tmpToggle"] --farmerkey $config["farmerKey"] --poolkey $($config["poolKey"]) --count 1 | Tee-Object -Variable plotLog | Out-Default
    }

    $plotName = $plotLog | where {$_ -match "plot-k32-"}
    $plotName = $plotName.Substring(11,$plotName.Length-11)

    # Log creation if logs are enabled
    if($config["logs"])
    {
        # Write log file
        Out-File -FilePath "$($config["logDir"])Create_$($plotName).log" -InputObject $plotLog -Encoding UTF8
    }

    # Rename plot for move
    if(Test-Path -Path "$($config["tmpDir"])$($plotName).plot")
    {
        Rename-Item -Path "$($config["tmpDir"])$($plotName).plot" -NewName "$($plotName).plotMove"
    }

    # Remove all tmp after failed
    Remove-Item "$($config["tmpDir"])$($plotName)*.tmp"

    # Get process id
    return "$($plotName).plotMove"
}

Function CreateFolder {
    Param(
        [String]$folder
    )

    # Create tmpDir directory
    $newItem = New-Item -ItemType Directory -Force -Path $folder

    # Displays creation of the directory
    PrintMsg -msg $UTlang.TempDirCreated -msg2 "-> $folder"

    # Takes a break
    start-sleep -s $smallTime
}

Function CheckConfig {
    Param(
        [String]$path,
        [String]$line
    )

    if([string]::IsNullOrEmpty($path))
    {
        # Information
        PrintMsg -msg $UTlang.PathTempNotFound -msg2 "-> " -msg3 $line -textColor "Blue" -backColor "Black" -sharpColor "Red"
        PrintMsg -msg $UTlang.ClickToExit -textColor "Red" -backColor "Black" -sharpColor "Red"
        $input = Read-Host
        break
    }

    if($line -eq "tmpDir")
    {
        if(!(Test-Path -Path $config["tmpDir"]))
        {
            # Information
            PrintMsg -msg $UTlang.FolderNotFound -msg2 $config["tmpDir"] -msg3 $UTlang.CreateIt -textColor "Red" -backColor "Black" -sharpColor "Red"
            PrintMsg -msg $UTlang.ClickToExit -textColor "Red" -backColor "Black" -sharpColor "Red"
            $input = Read-Host
            break
        }
        # Apply valpath
        $config["tmpDir"] = ValPath -path $config["tmpDir"]

        # Display a message
        PrintMsg -msg $UTlang.ValPathApply ": $line"
    }

    if($line -eq "chiaPlotterLoc")
    {
        if(!(Test-Path -Path $config["chiaPlotterLoc"]))
        {
            # Information
            PrintMsg -msg $UTlang.FolderNotFound -msg2 $config["chiaPlotterLoc"] -msg3 $UTlang.CreateIt -textColor "Red" -backColor "Black" -sharpColor "Red"
            PrintMsg -msg $UTlang.ClickToExit -textColor "Red" -backColor "Black" -sharpColor "Red"
            $input = Read-Host
            break
        }
        # Apply valpath
        $config["chiaPlotterLoc"] = ValPath -path $config["chiaPlotterLoc"]

        # Display a message
        PrintMsg -msg $UTlang.ValPathApply ": $line"
    }
}

Function CheckNewPackageVersion {
    # url github
    $gitHubApi = "https://api.github.com/repos/Maxxxi/PowershellForMadmax/releases/latest"

    # Get content
    $response = Invoke-WebRequest -Uri $gitHubApi -UseBasicParsing

    # Convert content
    $json = $response.Content | ConvertFrom-Json

    # Get version from GitHub
    $tagID = [string]$json.tag_name

    # if version file not exist
    if(!(Test-Path -Path $scriptDir\Version.txt))
    {
        PrintMsg -msg $UTlang.NeedUpdate -textColor "Red" -backColor "Black" -sharpColor "Red"

        # Takes a break
        start-sleep -s $smallTime
    }
    # url version file
    $softApiID = [string]"$scriptDir\Version.txt"

    # Get current version
    $currentID = get-content $softApiID

    # if current version equal or less than 
    if($currentID -lt $tagID)
    {
        PrintMsg -msg $UTlang.NewVersion -msg2 $tagID -msg3 $UTlang.NeedUpdate -textColor "Green" -backColor "Black" -sharpColor "Red"

        # Takes a break
        start-sleep -s $smallTime
    }
    return , $currentID, $tagID
}
