# Make powershell background to darkblue
$Host.UI.RawUI.BackgroundColor = "Black"
# Make powershell text to 
$Host.UI.RawUI.ForegroundColor = "Green"
# Load PSYaml module for read yaml file
$scriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

# Search for the name of the script
$scriptName = $MyInvocation.MyCommand.Name

# File import
Import-Module $scriptDir\PSYaml

# Intenationalization import
$CPlang = Import-LocalizedData -BaseDirectory Lang

# Importing functions
."$scriptDir\Functions\Utility.ps1"

# Get config.yaml file
[string[]]$fileContent = Get-Content "config.yaml"
$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }

# Convert config.yaml
$config = ConvertFrom-YAML $content

# Define valpath ( -isDir $true si fichier)
$config["logDir"]   = ValPath -path $config["logDir"]
$config["tmpDir"]   = ValPath -path $config["tmpDir"]
$config["tmpDir2"]  = ValPath -path $config["tmpDir2"]
$config["chiaPlotterLoc"] = ValPath -path $config["chiaPlotterLoc"]

# Define break time
$sleepTime = 300
$smallTime = 1
$midTime = 3
$bigTime = 5

# Clear powershell window
clear-host

# Get the date and time
if(($PSCulture) -eq "fr-FR"){ $dateTime = $((get-date).ToLocalTime()).ToString("dd-MM-yyyy_HH'h'mm'm'ss") }else{ $dateTime = $((get-date).ToLocalTime()).ToString("yyyy-MM-dd_hh'h'mm'm'ss") }

# Verification and allocation of disk space
$finalDir = SelectDisk -finaldir $config["finalDir"] -smallTime $smallTime -midTime $midTime -bigTime $bigTime

# Takes a break
start-sleep -s $smallTime 

# if the process movePlots has an iD, we retrieve it
if(($movePlots -eq $null))
{
    # Launch plot movement
    $movePlots = MovePlots -tmpdir $config["tmpDir"] -finaldir $finalDir -logs $config["logsMoved"] -logDir $config["logDir"] -smallTime $smallTime -midTime $midTime -bigTime $bigTime -sleepTime $sleepTime -dateTime $dateTime
}

# Takes a break
start-sleep -s $smallTime

# Start script
$createPlots = CreatePlots -threads $config["threads"] -buckets $config["buckets"] -buckets3 $config["buckets3"] -farmerkey $config["farmerkey"] -poolkey $config["poolKey"] -tmpdir $config["tmpDir"] -tmpdir2 $config["tmpDir2"] -finaldir $finalDir -tmptoggle $config["tmpToggle"] -chiaPlotterLoc $config["chiaPlotterLoc"] -logs $config["logs"] -logDir $config["logDir"] -smallTime $smallTime -midTime $midTime -bigTime $bigTime -dateTime $dateTime

# Takes a break
start-sleep -s $smallTime

# Resetting variables
$resetTempDir = $config["tmpDir"]
$resetFinalDir = $config["finalDir"]

# Check if chia_plot process is running
if((Get-Process -NAME "chia_plot" -erroraction "silentlycontinue") -eq $null)
{
    # Check if movePlots process is running (A VOIR, faut il fermer l'ancien processus de déplacement. Risque de corrompre les plots s'ils sont en cours de mouvement ???)
    if((Get-Process -ID $movePlots))
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

    # Takes a break
    start-sleep -s $smallTime

    # Display information
    PrintMsg -msg $CPlang.ResetVariablesInProgress

    # Resets variables
    Clear-Variable -Name ("resetTempDir","resetFinalDir")

    # Takes a break
    start-sleep -s $smallTime

    # Display information
    PrintMsg -msg $CPlang.ResetVariables

    # Takes a break
    start-sleep -s $midTime

    # Relaunch the creation of plots
    ."$scriptDir\$scriptName"
}

# Debug
pause