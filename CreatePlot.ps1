###################################
#   IMPORTING THE CONFIGURATION   #
###################################

# Load PSYaml module for read yaml file
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

# Search for the name of the script
$ScriptName = $MyInvocation.MyCommand.Name

# file import
Import-Module $ScriptDir\PSYaml
# Function import
."$ScriptDir\Functions\Utility.ps1"
."$ScriptDir\Functions\SelectDisk.ps1"

# Get config.yaml file
[string[]]$fileContent = Get-Content "config.yaml"
$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }

# Convert config.yaml
$config = ConvertFrom-YAML $content

# Define valpath ( -isDir $true si fichier)
$config['tmpdir'] = valPath -path $config['tmpdir']
$config['tmpdir2'] = valPath -path $config['tmpdir2']
$config['chiaPlotterLoc'] = valPath -path $config['chiaPlotterLoc']
$config['logDir'] = valPath -path $config['logDir']

# Define break
$smallTime = "1"
$bigTime = "5"

###############################################
#  Verification and allocation of disk space  #
###############################################

# retrieves the values
$finaldir = SelectDisk -result $config['finaldir'] -smallTime $smallTime -bigTime $bigTime

# Takes a break
start-sleep -s $smallTime

#####################################
#  Launching plot creation process  #
#####################################

# Start script
startCreating

# Takes a break
start-sleep -s $bigTime

############################################################
#  Restarts the script if the process is no longer active  #
############################################################

# We are looking for the creative process
$ChiaPlot = (Get-Process -Name "chia_plot" -Ea SilentlyContinue)

# Takes a break
start-sleep -s $smallTime

# Start script
#restart()
