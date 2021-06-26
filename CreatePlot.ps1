# Load PSYaml module for read yaml file
$scriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

# Search for the name of the script
$scriptName = $MyInvocation.MyCommand.Name

# File import
Import-Module $scriptDir\PSYaml

# Intenationalization import
$lang = Import-LocalizedData -BaseDirectory Lang

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
$midTime = 5
$bigTime = 10

# check if the creation process is in progress
$chiaPlotProcess = (Get-Process -Name "chia_plot" -erroraction "silentlycontinue")

# If the process is not running
if(($chiaPlotProcess) -eq $null)
{
    # Verification and allocation of disk space
    $finalDir = SelectDisk -finaldir $config["finalDir"] -smallTime $smallTime -midTime $midTime -bigTime $bigTime

    # Takes a break
    start-sleep -s $smallTime 

    # if the process movePlots has an iD, we retrieve it
    if(!($movePlots -eq $null))
    {
        # check if the movePlots process is in progress
        $MovePlotProcess = (Get-Process -ID $movePlots -erroraction "silentlycontinue")
    }

    # If the process is not running (A REVOIR POUR LE CHANGEMENT AUTOMATIQUE DE STOCKAGE)
    if(($MovePlotProcess) -eq $null)
    {
        # Launch plot movement
        $movePlots = MovePlots -tmpdir $config["tmpDir"] -finaldir $finalDir -smallTime $smallTime -midTime $midTime -bigTime $bigTime -sleepTime $sleepTime

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
    $createPlots = CreatePlots -threads $config["threads"] -buckets $config["buckets"] -buckets3 $config["buckets3"] -farmerkey $config["farmerkey"] -poolkey $config["poolKey"] -tmpdir $config["tmpDir"] -tmpdir2 $config["tmpDir2"] -finaldir $finalDir -tmptoggle $config["tmpToggle"] -chiaPlotterLoc $config["chiaPlotterLoc"] -logs $config["logs"] -logDir $config["logDir"] -smallTime $smallTime -midTime $midTime -bigTime $bigTime
 
    # Affichage des logs de création (A REVOIR NE FONCTIONNE PAS)
    Write-Host @createPlots

    # Displays the process ID
    PrintMsg -msg "Process ID for creating plot is "$createPlots.ID

    # Takes a break
    start-sleep -s $smallTime
}
else
{
    # Displays error message
    PrintMsg -msg "Plot creation is already in progress, close this window in $bigTime seconds" -blu $true -backColor "black" -sharpColor "red" -textColor "red"

    # Takes a break
    start-sleep -s $bigTime

    exit
}
pause