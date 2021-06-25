# Load PSYaml module for read yaml file
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

# Search for the name of the script
$ScriptName = $MyInvocation.MyCommand.Name

# File import
Import-Module $ScriptDir\PSYaml

# Function import
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
$bigTime = 5

# Verification and allocation of disk space
$finaldir = SelectDisk -finaldir $config['finaldir'] -smallTime $smallTime -bigTime $bigTime

# Takes a break
start-sleep -s $smallTime

# Launch of the plot movement
$movePlots = MovePlots -tmpdir $config['tmpdir'] -finaldir $finaldir -smallTime $smallTime -bigTime $bigTime -sleepTime $sleepTime

# Takes a break
start-sleep -s $smallTime

# Start script
$CreatePlots = CreatePlots -threads $config['threads'] -buckets $config['buckets'] -buckets3 $config['buckets3'] -farmerkey $config['farmerkey'] -poolkey $config['poolkey'] -tmpdir $config['tmpdir'] -tmpdir2 $config['tmpdir2'] -finaldir $finaldir -tmptoggle $config['tmptoggle'] -chiaPlotterLoc $config['chiaPlotterLoc'] -logs $config['logs'] -logDir $config['logDir'] -smallTime $smallTime -bigTime $bigTime


