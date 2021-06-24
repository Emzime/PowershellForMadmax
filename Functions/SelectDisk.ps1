Function SelectDisk
{
    Param (
        [Object]$result,
        [int]$smallTime,
        [int]$bigTime
    )
    
    # Check if CopyPlots process is running
    $ProcessCopyPlots = (Get-Process -NAME "CopyPlots" -Ea SilentlyContinue)

    # Defines space required
    If (!($ProcessCopyPlots -eq $null)){$RequiredSpace = 204}else{$RequiredSpace = 102}

    # Displays information about the space required
    PrintMsg -msg "Note: the space requirement is ""$RequiredSpace Go"" (see: note in the script)"

    # Pausing
    start-sleep -s $smallTime
    
    foreach ($_ in $result)
    {
        # we query the selected hard drives
        $diskSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($_):'" | Select-Object FreeSpace

        # Defines space in Gio
        $diskSpace = [int] [math]::Round($diskSpace.FreeSpace / 1073741824)

        # Check which disk is available
        if ($diskSpace -ge $RequiredSpace)
        {    
            # Displays available capacity
            PrintMsg -msg "Final disk used $($_):\ -> Free space remaining $diskSpace Go"

            # Recovers the letter of the hard disk
            return "$($_):\"
        
            # Stop if space available
            break
        }
    }
}
