# Make powershell background to darkblue
$Host.UI.RawUI.BackgroundColor = "Black"

# Make powershell text to 
$Host.UI.RawUI.ForegroundColor = "Yellow"

# Make name to window
$Host.UI.RawUI.WindowTitle = "PowerShell For madMAx"

# Get path file
$global:scriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

# Search for the name of the script
$scriptName = $MyInvocation.MyCommand.Name

# Get policy
$GetExecutionPolicy = Get-ExecutionPolicy

# Set policy
$checkExecutionPolicy = "Unrestricted"

# Check if policy is Unrestricted
if(!([string]$GetExecutionPolicy -eq "$checkExecutionPolicy")){
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $testadmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if ($testadmin -eq $false){
        Start-Process powershell.exe -windowstyle hidden -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
        $setEx = Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -force
    }
}

# Takes a break
start-sleep -s 1

# File import
Import-Module $scriptDir\PSYaml

# Intenationalization import
$CPlang = Import-LocalizedData -BaseDirectory "Scripts\Lang"

# Importing functions
."$scriptDir\Utility.ps1"

# Check script version
CheckNewPackageVersion

# Get config.yaml file
[string[]]$fileContent = Get-Content "config.yaml"
$content = ''
foreach ($line in $fileContent){ $content = $content + "`n" + $line }

# Convert config.yaml
$global:config = ConvertFrom-YAML $content

# Define break time
$global:sleepTime = 300
$global:smallTime = 1
$global:midTime = 3
$global:bigTime = 5
$global:winHeight = 10
$global:winWidth  = 220

# Set default tmpDir2 directory if not specified
if([string]::IsNullOrEmpty($config["tmpDir2"])){
    $config["tmpDir2"] = $config["tmpDir"]
    $config["tmpDir2"] = ValPath -path $config["tmpDir2"]
}

# Set log folder
if($config["logs"] -or $config["logsMoved"]){
    $config["logDir"] = $scriptDir.Substring(0,$scriptDir.Length-8) + "\logs\"
    if(!(Test-Path $config["logDir"])){
        $addFolder = New-Item -ItemType Directory -Force -Path $config["logDir"]
    }
}

# Check if config is ok
CheckConfig -path $config["threads"] -line "threads"
CheckConfig -path $config["buckets"] -line "buckets"
CheckConfig -path $config["farmerKey"] -line "farmerKey"
CheckConfig -path $config["poolContract"] -line "poolContract"
CheckConfig -path $config["tmpDir"] -line "tmpDir"
CheckConfig -path $config["tmpDir2"] -line "tmpDir2"
CheckConfig -path $config["finalDir"] -line "finalDir"
CheckConfig -path $config["chiaPlotterLoc"] -line "chiaPlotterLoc"

# Takes a break
start-sleep -s $smallTime

# Set tmptoggle if active and tmpDir2 ative
if( ($config["tmpToggle"]) -AND (($config["tmpDir2"] -eq $config["tmpDir"]))){
    # Display information
    $PrintMsgTmpToggle = $CPlang.tmpToggleDeactivate
    # Turn off
    $config["tmpToggle"] = $false
}
elseif(!($config["tmpToggle"])){
    # Display information
    $PrintMsgTmpToggle = $CPlang.tmpToggleFalse
}
else{
    # Display information
    $PrintMsgTmpToggle = $CPlang.tmpToggleTrue
}

# Takes a break
start-sleep -s $smallTime

# Display message
PrintMsg -msg $PrintMsgTmpToggle

# Takes a break
start-sleep -s $smallTime 

# Get date and time conversion
if(($PSCulture) -eq "fr-FR"){$global:dateTime = $((get-date).ToLocalTime()).ToString("dd-MM-yyyy_HH'h'mm'm'ss")}else{$global:dateTime = $((get-date).ToLocalTime()).ToString("yyyy-MM-dd_hh'h'mm'm'ss")}

# Verification and allocation of disk space
$finalSelectDisk = SelectDisk

# stop if there is no more space
if(!($finalSelectDisk)){
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
if(!(Get-Process -NAME "chia_plot" -erroraction "silentlycontinue")){
    # Define resetting variables
    $resetTempDir   = $config["tmpDir"]
    $resetFinalDir  = $config["finalDir"]

    # if directory not exist, create it
    if(!(Test-Path -Path $finalSelectDisk)){
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
    start-sleep -s $midTime

    # Relaunch the creation of plots
    ."$scriptDir\$scriptName"
}