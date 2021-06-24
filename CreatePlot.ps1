#######################################
#   IMPORTATION DE LA CONFIGURATION   #
#######################################

# Load PSYaml module for read yaml file
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module $ScriptDir\PSYaml

# Get config.yaml file
[string[]]$fileContent = Get-Content "config.yaml"
$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }

# Convert config.yaml
$config = ConvertFrom-YAML $content

# Launch in admin mode if logs are enabled
if($config['logs'])
{
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
    {  
      $arguments = "& '" +$myinvocation.mycommand.definition + "'"
      Start-Process powershell -Verb runAs -ArgumentList $arguments
      Break
    }

    #  Log file time stamp:
    $logTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"

    # Log directory
    $logDir = .$config['logDir']"\log-$logTime.log"

    # Start logging
    start-transcript -path "$logDir"
}

# Search for the name of the script
$ScriptName = $MyInvocation.MyCommand.Name

# Short break
$smallTime = 1

# Big break
$bigTime = 5

# Minimum space required (for 1 plot)
$PlotSpace = 102

###############################################
#  Verification and allocation of disk space  #
###############################################

# We recalculate the required space (If CopyPlot is in progress, the script reserves the double of the required space, the time of the copy)
$ProcessCopyPlots = (Get-Process -NAME "CopyPlots" -Ea SilentlyContinue)

If (!($ProcessCopyPlots -eq $null))
{
    $QuerySpace = ($PlotSpace * 2)
}
else
{
    $QuerySpace = $PlotSpace
}

foreach ($_ in $config['finaldir']) 
{
    # we query the selected hard drives
    $diskSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($_):'" | Select-Object FreeSpace

    # Defines space in Gio
    $freeSpace = [int] [math]::Round($diskSpace.FreeSpace / 1073741824)

    # Check which disk is available
    if ($freeSpace -ge $QuerySpace)
    {
        # Recovers the letter of the hard disk
        $copyDisk = "$($_):\"

        # Assigns the available capacity
        $freeDisk = $freeSpace
        
        # Stop if space available
        break
    }           
}
        
#################################################
#  Displays information about the space required  #
#################################################
Write-Host ("`n#######################################################################") -ForegroundColor Green
Write-Host ("Note: the space requirement is $QuerySpace Go (see: note in the script)")
Write-Host ("#######################################################################`n") -ForegroundColor Green

# Pausing
start-sleep -s $smallTime
    
#######################################
#  Displays the final directory used  #
#######################################
Write-Host ("#########################################") -ForegroundColor Green
Write-Host ("Temporary disk used -> ") $config['tmpdir']
Write-Host ("#########################################`n") -ForegroundColor Green

# Pausing
start-sleep -s $smallTime

######################################
#     Displays available capacity    #
######################################
Write-Host ("#####################################################") -ForegroundColor Green
Write-Host ("Final disk used -> $copyDisk -> Free space -> $freeDisk Go")
Write-Host ("#####################################################`n") -ForegroundColor Green

# Pausing
start-sleep -s $smallTime

###############################
#   Creation launch message   #
###############################
Write-Host ("###################################") -ForegroundColor Green
Write-Host ("Launching the plot creation process")
Write-Host ("###################################`n") -ForegroundColor Green

# Pausing
start-sleep -s $smallTime

#########################################
#  Launching the plot creation process  #
#########################################
$chiaPlotterLoc = $config['chiaPlotterLoc'] # LIGNE A REVOIR
.$chiaPlotterLoc\chia_plot.exe --threads $config['threads'] --buckets $config['buckets'] --tmpdir $config['tmpdir'] --farmerkey $config['farmerkey'] --poolkey $config['poolkey'] --count 1

# Pausing
start-sleep -s $bigTime

############################################################
#  Restarts the script if the process is no longer active  #
############################################################

# We are looking for the creative process
$ChiaPlot = (Get-Process -Name "chia_plot" -Ea SilentlyContinue)

# Pausing
start-sleep -s $smallTime

# Checks that the chia_plot process is not running
If (($ChiaPlot) -eq $Null)
{        
    # Starts the move window if the process does not exist
    $StartCopyPlots = new-object System.Diagnostics.ProcessStartInfo
    $StartCopyPlots.FileName = "$pshome\powershell.exe"
    $StartCopyPlots.Arguments = "-NoExit -windowstyle Minimized -Command `$Host.UI.RawUI.WindowTitle=`'CopyPlots`'; while ('$true') {robocopy $config['tmpdir'] $copyDisk *.plot /mov; sleep 300}"

    # Checks the existence of the process
    If (($ProcessCopyPlots -eq $null))
    {
        # Starts the process
        $StartCopyProcess = [Diagnostics.Process]::Start($StartCopyPlots)
    
        # Informative message
        Write-Host ("#######################################") -ForegroundColor Green
        Write-Host ("CopyPlots process successfully launched")
        Write-Host ("#######################################`n") -ForegroundColor Green
    }
    else
    {   
        # Informative message
        Write-Host ("#####################################") -ForegroundColor Green
        Write-Host ("CopyPlots process already in progress")
        Write-Host ("#####################################`n") -ForegroundColor Green
    }

    # Pausing
    start-sleep -s $smallTime

    # Informative message
    Write-Host ("`n#################################################################") -ForegroundColor Red -BackgroundColor Black
    Write-Host ("This window will close in 10 seconds") -ForegroundColor Red -BackgroundColor Black
    Write-Host ("The creation of the next plot will start when this window is closed") -ForegroundColor Red -BackgroundColor Black
    Write-Host ("###################################################################`n") -ForegroundColor Red -BackgroundColor Black

    # Stop logs if activated
    if($config['logs'])
    {
        Stop-Transcript
    }

    # Pausing
    start-sleep -s $bigTime

    # Launch of a new plot creation
    cmd /c start powershell -NoExit -file $ScriptDir\$ScriptName

    # Pausing
    start-sleep -s $bigTime

    # We leave this script window
    exit
}
