# Make powershell background to darkblue
$Host.UI.RawUI.BackgroundColor = "Black"

# Make powershell text to 
$Host.UI.RawUI.ForegroundColor = "Yellow"

# Make name to window
$Host.UI.RawUI.WindowTitle = "PowerShell For madMAx"

# Get path file
$global:scriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

# Unblock file
Unblock-File -Path $scriptDir

# Search for the name of the script
$scriptName = $MyInvocation.MyCommand.Name

# File import
Import-Module $scriptDir\PSYaml | Unblock-File

# Intenationalization import
$CPlang = Import-LocalizedData -BaseDirectory "Scripts\Lang"

# Importing functions
."$scriptDir\Utility.ps1" | Unblock-File

# Get config.yaml file
[string[]]$fileContent = Get-Content "config.yaml"
$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }

# Convert config.yaml
$global:config = ConvertFrom-YAML $content

# Define break time
$global:sleepTime = 300
$global:smallTime = 1
$global:midTime = 3
$global:bigTime = 5

# Set default logDir directory if not specified
if($config["logs"] -or $config["logsMoved"])
{
    # if logdir not empty
    if([string]::IsNullOrEmpty($config["logDir"]))
    {
        # 8 char for remove "\Scripts" and add "\logs"
        $config["logDir"] = $scriptDir.Substring(0,$scriptDir.Length-8) + "\logs"
    }
    # if directory not exist, create it
    if(!(Test-Path -Path $config["logDir"])){CreateFolder -folder $config["logDir"]}
    # Apply ValPath
    $config["logDir"] = ValPath -path $config["logDir"]
    $PrintMsgLogDir = "logDir |"
}
     
# Takes a break
#start-sleep -s $smallTime

# Check if tmpDir directory is specified
if([string]::IsNullOrEmpty($config["tmpDir"]))
{
    # Information
    PrintMsg -msg $CPlang.PathTempNotFound -msg2 "-> tmpDir" -textColor "Red" -backColor "Black" -sharpColor "Red"
    PrintMsg -msg $CPlang.ClickToExit -textColor "Red" -backColor "Black" -sharpColor "Red"
    $input = Read-Host
    exit
}
else 
{
    # if directory not exist, create it
    if(!(Test-Path -Path $config["tmpDir"])){CreateFolder -folder $config["tmpDir"]}    
    # Apply ValPath
    $config["tmpDir"] = ValPath -path $config["tmpDir"]
    $PrintMsgTmpDir = "tmpDir |"
}

# Takes a break
#start-sleep -s $smallTime

# Set default tmpDir2 directory if not specified
if([string]::IsNullOrEmpty($config["tmpDir2"]))
{
    # Set default tmpDir2 directory
    $config["tmpDir2"] = $config["tmpDir"]
}
else 
{
    # if directory not exist, create it
    if(!(Test-Path -Path $config["tmpDir2"])){CreateFolder -folder $config["tmpDir2"]}
    # Apply ValPath
    $config["tmpDir2"] = ValPath -path $config["tmpDir2"]
    $PrintMsgTmpDir2 = "tmpDir2 |"
}

# Check if chiaPlotterLoc directory is specified
if([string]::IsNullOrEmpty($config["chiaPlotterLoc"]))
{
    # Information
    PrintMsg -msg $CPlang.PathTempNotFound -msg2 "-> chiaPlotterLoc" -textColor "Red" -backColor "Black" -sharpColor "Red"
    PrintMsg -msg $CPlang.ClickToExit -textColor "Red" -backColor "Black" -sharpColor "Red"
    $input = Read-Host
    exit
}
else 
{
    # Apply ValPath
    $config["chiaPlotterLoc"] = ValPath -path $config["chiaPlotterLoc"]
    $PrintMsgChiaPlotterLoc = "chiaPlotterLoc"
}

# Display message for ValPath
PrintMsg -msg $CPlang.ValPathApply ":$PrintMsgLogDir $PrintMsgTmpDir $PrintMsgTmpDir2$PrintMsgChiaPlotterLoc$PrintMsgTmpToggle"

# Takes a break
start-sleep -s $smallTime

# Set tmptoggle if active and tmpDir2 ative
if( ($config["tmpToggle"]) -AND (($config["tmpDir2"] -eq $config["tmpDir"])))
{
    # Display information
    $PrintMsgTmpToggle = $CPlang.tmpToggleDeactivate
    # Turn off
    $config["tmpToggle"] = $false
    # Takes a break
    start-sleep -s $midTime
}
elseif(!($config["tmpToggle"]))
{
    # Display information
    $PrintMsgTmpToggle = $CPlang.tmpToggleFalse
    # Takes a break
    start-sleep -s $smallTime
}
else 
{
    # Display information
    $PrintMsgTmpToggle = $CPlang.tmpToggleTrue
    # Takes a break
    start-sleep -s $smallTime
}

# Display message
PrintMsg -msg $PrintMsgTmpToggle

# Takes a break
start-sleep -s $smallTime 

# Get date and time conversion
if(($PSCulture) -eq "fr-FR"){$global:dateTime = $((get-date).ToLocalTime()).ToString("dd-MM-yyyy_HH'h'mm'm'ss")}else{$global:dateTime = $((get-date).ToLocalTime()).ToString("yyyy-MM-dd_hh'h'mm'm'ss")}

# Verification and allocation of disk space
$finalSelectDisk = SelectDisk

# stop if there is no more space
if(!($finalSelectDisk))
{
    PrintMsg -msg $CPlang.FreeSpaceFull -textColor "Red" -backColor "Black" -sharpColor "Red"
    PrintMsg -msg $CPlang.ClickToExit -textColor "Red" -backColor "Black" -sharpColor "Red"
    $input = Read-Host
    exit
}

# Start script
$newPlotLogName = CreatePlots

# Takes a break
start-sleep -s $midTime

# Check if chia_plot process is running
if(!(Get-Process -NAME "chia_plot" -erroraction "silentlycontinue"))
{
    # Define resetting variables
    $resetTempDir   = $config["tmpDir"]
    $resetFinalDir  = $config["finalDir"]

    # if directory not exist, create it
    if(!(Test-Path -Path $finalSelectDisk))
    {
        # Create folder
        CreateFolder -folder $finalSelectDisk
        # Takes a break
        start-sleep -s $smallTime
        # Modify attribut of folder
        $makeAttrib = (get-item "$folder" -Force).Attributes -= 'Hidden'
        # Takes a break
        start-sleep -s $smallTime
    } 

    # Apply ValPath
    $config["tmpDir2"] = ValPath -path $finalSelectDisk

    # Displays creation of the directory
    PrintMsg -msg $CPlang.ValPathApply -msg2 "$finalSelectDisk"

    # Takes a break
    start-sleep -s $smallTime

    # Launch plot movement
    $movePlots = MovePlots -newPlotLogName $newPlotLogName -finalSelectDisk $finalSelectDisk

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
    If (Get-Process -Name "Robocopy" -ErrorAction "silentlycontinue")
    {
        $global:requiredSpace = 204
    }
    else
    {
        $global:requiredSpace = 102
    }

    # Takes a break
    start-sleep -s $midTime

    # Relaunch the creation of plots
    ."$scriptDir\$scriptName"
}