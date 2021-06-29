# Make powershell background to darkblue
$Host.UI.RawUI.BackgroundColor = "Black"

# Make powershell text to 
$Host.UI.RawUI.ForegroundColor = "Yellow"

# Make name to window
$Host.UI.RawUI.WindowTitle='PowerShell For madMAx'

# Load PSYaml module for read yaml file
$scriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

# Search for the name of the script
$scriptName = $MyInvocation.MyCommand.Name

# File import
Import-Module $scriptDir\PSYaml

# Intenationalization import
$CPlang = Import-LocalizedData -BaseDirectory Lang

# Importing functions
."$scriptDir\Utility.ps1"

# Get config.yaml file
[string[]]$fileContent = Get-Content "config.yaml"
$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }

# Convert config.yaml
$config = ConvertFrom-YAML $content

# Define break time
$sleepTime = 300
$smallTime = 1
$midTime = 3
$bigTime = 5

# Clear window
Clear-Host

# Apply ValPath
CheckPath -logDir $config["logDir"] -tmpDir $config["tmpDir"] -tmpDir2 $config["tmpDir2"] -chiaPlotterLoc $config["chiaPlotterLoc"]
# Clear window
Clear-Host

# Get date and time conversion
if(($PSCulture) -eq "fr-FR")
{
    $dateTime = $((get-date).ToLocalTime()).ToString("dd-MM-yyyy_HH'h'mm'm'ss")
}
else
{
    $dateTime = $((get-date).ToLocalTime()).ToString("yyyy-MM-dd_hh'h'mm'm'ss")
}

# Verification and allocation of disk space
$SelectDisk = SelectDisk -finaldir $config["finalDir"] -requiredSpace $requiredSpace -smallTime $smallTime -midTime $midTime -bigTime $bigTime

# stop if there is no more space
if(!($SelectDisk))
{
    PrintMsg -msg $UTlang.FreeSpaceFull -textColor "Red" -backColor "Black" -sharpColor "Red"
    PrintMsg -msg $UTlang.ProcessMoveClosedImpossibleEnter -textColor "Red" -backColor "Black" -sharpColor "Red"
    $input = Read-Host
    exit
}

# Start script
$createPlots = CreatePlots -threads $config["threads"] -buckets $config["buckets"] -buckets3 $config["buckets3"] -farmerkey $config["farmerkey"] -poolkey $config["poolKey"] -tmpdir $config["tmpDir"] -tmpdir2 $config["tmpDir2"] -finaldir $SelectDisk -tmptoggle $config["tmpToggle"] -chiaPlotterLoc $config["chiaPlotterLoc"] -logs $config["logs"] -logDir $config["logDir"] -smallTime $smallTime -midTime $midTime -bigTime $bigTime -dateTime $dateTime

# Takes a break
start-sleep -s $midTime

# Check if chia_plot process is running
if((Get-Process -NAME "chia_plot" -erroraction "silentlycontinue") -eq $null)
{
    # Define resetting variables
    $resetTempDir   = $config["tmpDir"]
    $resetFinalDir  = $config["finalDir"]

    # if the process movePlots has an iD, we retrieve it
    If (!(Get-Process -Name "Robocopy" -ErrorAction SilentlyContinue))
    {
        # Launch plot movement
        $movePlots = MovePlots -tmpdir $config["tmpDir"] -finaldir $SelectDisk -logs $config["logsMoved"] -logDir $config["logDir"] -smallTime $smallTime -midTime $midTime -bigTime $bigTime -sleepTime $sleepTime -dateTime $dateTime
    }
    else 
    {
        # If the final disk is different from the new one, the transfer window is closed and another one is opened
        if(!($SelectDisk -eq $resetFinalDir))
        {
            # Displays the process ID if it is found
            if($movePlots)
            {
                # Display information
                PrintMsg -msg $CPlang.ProcessMoveClosing -msg2  $movePlots -msg3 ")"
                # Takes a break
                start-sleep -s $smallTime
                # Stopping the moving process
                Stop-Process -ID $movePlots
                # Takes a break
                start-sleep -s $smallTime
                # Display information
                PrintMsg -msg $CPlang.ProcessMoveClosed
            }
            else 
            {
                PrintMsg -msg $CPlang.ProcessMoveClosedImpossible -textColor "Red" -backColor "Black" -sharpColor "Red"
                PrintMsg -msg $CPlang.ProcessMoveClosedImpossibleEnter -textColor "Red" -backColor "Black" -sharpColor "Red"
                $input = Read-Host
            }

            # Takes a break
            start-sleep -s $smallTime
            # Display information
            PrintMsg -msg $CPlang.ProcessMoveRelaunch
            # Takes a break
            start-sleep -s $smallTime
            # Launch plot movement
            $movePlots = MovePlots -tmpdir $config["tmpDir"] -finaldir $SelectDisk -logs $config["logsMoved"] -logDir $config["logDir"] -smallTime $smallTime -midTime $midTime -bigTime $bigTime -sleepTime $sleepTime -dateTime $dateTime
        }
        else 
        {
            # Displays the process ID if it is found
            if($movePlots)
            {
                PrintMsg -msg $CPlang.ProcessMoveAlreadyLaunch -msg2 $CPlang.ProcessID  -msg3 $movePlots
            }
            else 
            {
                PrintMsg -msg $CPlang.ProcessMoveAlreadyLaunch
            }
        }
    }

    # Takes a break
    start-sleep -s $smallTime

    # Display information
    PrintMsg -msg $CPlang.ResetVariablesInProgress

    # Takes a break
    start-sleep -s $smallTime

    # Resets variables
    Clear-Variable -Name ("resetTempDir","resetFinalDir")

    # Takes a break
    start-sleep -s $smallTime

    # Display information
    PrintMsg -msg $CPlang.ResetVariables

    # Takes a break
    start-sleep -s $smallTime

    # Checks if the copy process is running and allocates double the space for the next plot
    If (Get-Process -Name "Robocopy" -ErrorAction SilentlyContinue)
    {
        $requiredSpace = 204
    }
    else
    {
        $requiredSpace = 102
    }

    # Takes a break
    start-sleep -s $midTime

    # Relaunch the creation of plots
    ."$scriptDir\$scriptName"
}