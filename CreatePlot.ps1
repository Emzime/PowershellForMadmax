# Load PSYaml module for read yaml file
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

# Search for the name of the script
$ScriptName = $MyInvocation.MyCommand.Name

# File import
Import-Module $ScriptDir\PSYaml

# Importing functions
."$ScriptDir\Functions\Utility.ps1"

# Get config.yaml file
[string[]]$fileContent = Get-Content "config.yaml"
$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }

# Convert config.yaml
$config = ConvertFrom-YAML $content

# Define valpath ( -isDir $true si fichier)
$config['logDir'] = valPath -path $config['logDir']
$config['tmpdir'] = valPath -path $config['tmpdir']
$config['tmpdir2'] = valPath -path $config['tmpdir2']
$config['chiaPlotterLoc'] = valPath -path $config['chiaPlotterLoc']

# Define break time
$sleepTime = 300
$smallTime = 1
$midTime = 5
$bigTime = 10

# check if the creation process is in progress
$ChiaPlotProcess = (Get-Process -Name "chia_plot" -Ea SilentlyContinue)

# If the process is not running
if(($ChiaPlotProcess) -eq $null)
{
    # Verification and allocation of disk space
    $finaldir = SelectDisk -finaldir $config['finaldir'] -smallTime $smallTime -midTime $midTime -bigTime $bigTime

    # Takes a break
    start-sleep -s $smallTime 

    # if the process movePlots has an iD, we retrieve it
    if(!($movePlots -eq $null))
    {
        # check if the movePlots process is in progress
        $MovePlotProcess = (Get-Process -ID $movePlots -erroraction 'silentlycontinue')
    }

    # If the process is not running (A REVOIR POUR LE CHANGEMENT AUTOMATIQUE DE STOCKAGE)
    if(($MovePlotProcess) -eq $null)
    {
        # Launch plot movement
        $movePlots = MovePlots -tmpdir $config['tmpdir'] -finaldir $finaldir -smallTime $smallTime -midTime $midTime -bigTime $bigTime -sleepTime $sleepTime

        # Displays the process ID
        PrintMsg -msg "Process ID for moving plot is $movePlots"
    }
    else
    {
        # Displays error message
        PrintMsg -msg "The displacement process ($movePlots) is already underway"
    }
    
    # Takes a break
    start-sleep -s $smallTime

    # Start script
    $CreatePlots = CreatePlots -threads $config['threads'] -buckets $config['buckets'] -buckets3 $config['buckets3'] -farmerkey $config['farmerkey'] -poolkey $config['poolkey'] -tmpdir $config['tmpdir'] -tmpdir2 $config['tmpdir2'] -finaldir $finaldir -tmptoggle $config['tmptoggle'] -chiaPlotterLoc $config['chiaPlotterLoc'] -logs $config['logs'] -logDir $config['logDir'] -smallTime $smallTime -midTime $midTime -bigTime $bigTime

    # Displays the process ID
    PrintMsg -msg "Process ID for creating plot is $CreatePlots"

    # Takes a break
    start-sleep -s $smallTime

    # Stop logs if activated
    if($config['logs'])
    {
        Stop-Transcript
    }
}
else
{
    # Displays information about the space required
    PrintMsg -msg "Plot creation is already in progress, close this window in $bigTime seconds" -blu $true -backColor "black" -sharpColor "red" -textColor "red"

    # Takes a break
    start-sleep -s $bigTime

    exit
}