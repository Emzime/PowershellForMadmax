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
        $newPlotLogName = [String]$newPlotLogName,
        $finalSelectDisk = [String]$finalSelectDisk
    )
    # Starts the move window if the process does not exist
    $startMovePlots = new-object System.Diagnostics.ProcessStartInfo
    $startMovePlots.FileName = "$pshome\powershell.exe"

    # Get plot Name
    $newPlotNamePath = "$finalSelectDisk$newPlotLogName"
    $newPlotName = $newPlotNamePath.Substring(0, $newPlotNamePath.Length-9)

    # Log creation if logs are enabled
    if($config["logsMoved"])
    {
        # Get plot name log
        $newPlotLogName = $config["logDir"] + "Moved_" + $newPlotLogName.Substring(11,$newPlotLogName.Length-11) + ".log"
        # Starts the creation of plots with logs
         $startMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle='MovePlots'; robocopy $($config["tmpDir"]) $finalSelectDisk *.plotTEMP /unilog:'$newPlotLogName' /tee /mov; rename-item -path '$finalSelectDisk$newPlotLogName' -NewName '$newPlotName.plot'; exit"
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
        $startMovePlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle='MovePlots'; robocopy $($config["tmpDir"]) $finalSelectDisk *.plotTEMP /mov; rename-item -path '$finalSelectDisk$newPlotLogName' -NewName '$newPlotName.plot'; exit"
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
        # Starts the creation of plots without logs
        if(!([string]::IsNullOrEmpty($config["poolContract"])))
        {
            $processCreatePlots = ."$($config["chiaPlotterLoc"])\chia_plot.exe" --threads $config["threads"] --buckets $config["buckets"] --buckets3 $config["buckets3"] --tmpdir $config["tmpDir"] --tmpdir2 $config["tmpDir2"] --tmptoggle $config["tmpToggle"] --farmerkey $config["farmerKey"] --contract $($config["poolContract"]) --count 1 | tee "$newPlotLogName1" | Out-Default
        }
        else
        {
            $processCreatePlots = ."$($config["chiaPlotterLoc"])\chia_plot.exe" --threads $config["threads"] --buckets $config["buckets"] --buckets3 $config["buckets3"] --tmpdir $config["tmpDir"] --tmpdir2 $config["tmpDir2"] --tmptoggle $config["tmpToggle"] --farmerkey $config["farmerKey"] --poolkey $($config["poolKey"]) --count 1 | tee "$newPlotLogName1" | Out-Default
        }
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
        if(!([string]::IsNullOrEmpty($config["poolContract"])))
        {
            $processCreatePlots = ."$($config["chiaPlotterLoc"])\chia_plot.exe" --threads $config["threads"] --buckets $config["buckets"] --buckets3 $config["buckets3"] --tmpdir $config["tmpDir"] --tmpdir2 $config["tmpDir2"] --tmptoggle $config["tmpToggle"] --farmerkey $config["farmerKey"] --contract $($config["poolContract"]) --count 1 | Out-Default
        }
        else
        {
            $processCreatePlots = ."$($config["chiaPlotterLoc"])\chia_plot.exe" --threads $config["threads"] --buckets $config["buckets"] --buckets3 $config["buckets3"] --tmpdir $config["tmpDir"] --tmpdir2 $config["tmpDir2"] --tmptoggle $config["tmpToggle"] --farmerkey $config["farmerKey"] --poolkey $($config["poolKey"]) --count 1 | Out-Default
        }

        # Get log name
        $plotReName = get-childitem -Path $($config["tmpDir"]) *.plot | rename-item -NewName {$_.name -replace '.plot','.plotTEMP'}
        $plotName = get-childitem -Path $($config["tmpDir"]) *.plotTEMP
    }

    # Get process id
    return $plotName
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
        # Create Message box
        $msgUpd = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $msgUpd2 = [System.Windows.Forms.MessageBox]::Show($UTlang.NeedUpdate, $UTlang.TitleUpdate, 1)
        # Exit if Ok is clicked
        if ($msgUpd2 -eq "Ok")
        {
            Start-Process "https://github.com/Maxxxi/PowershellForMadmax/releases/tag/$tagID"
            Exit $LASTEXITCODE
        }
    }
    # url version file
    $softApiID = [string]"$scriptDir\Version.txt"
    # Get current version
    $currentID = get-content $softApiID
    # if current version equal or less than 
    if($currentID -lt $tagID)
    {
        # Create Message box
        $msgUpd = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $msgUpd2 = [System.Windows.Forms.MessageBox]::Show($UTlang.NeedUpdate, $UTlang.TitleUpdate, 1)
        # Exit if Ok is clicked
        if ($msgUpd2 -eq "Ok")
        {
            Start-Process "https://github.com/Maxxxi/PowershellForMadmax/releases/tag/$tagID"
            exit $LASTEXITCODE
        }
    }
}

# @Use WindowSize -Height 10 -Width 220
Function WindowSize {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [int]$Height = $winHeight,
        [Parameter(Mandatory=$False,Position=1)]
        [int]$Width = $winWidth
    )
    $console = $host.ui.rawui
    $ConBuffer  = $console.BufferSize
    $ConSize = $console.WindowSize

    $currWidth = $ConSize.Width
    $currHeight = $ConSize.Height

    # if height is too large, set to max allowed size
    if ($Height -gt $host.UI.RawUI.MaxPhysicalWindowSize.Height)
    {
        $Height = $host.UI.RawUI.MaxPhysicalWindowSize.Height
    }

    # if width is too large, set to max allowed size
    if ($Width -gt $host.UI.RawUI.MaxPhysicalWindowSize.Width)
    {
        $Width = $host.UI.RawUI.MaxPhysicalWindowSize.Width
    }

    # If the Buffer is wider than the new console setting, first reduce the width
    If ($ConBuffer.Width -gt $Width )
    {
       $currWidth = $Width
    }
    # If the Buffer is higher than the new console setting, first reduce the height
    If ($ConBuffer.Height -gt $Height )
    {
        $currHeight = $Height
    }
    # initial resizing if needed
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.size($currWidth,$currHeight)

    # Set the Buffer
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size($Width,2000)

    # Now set the WindowSize
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.size($Width,$Height)
}