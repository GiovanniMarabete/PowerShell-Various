function get-ServerHWInfo {
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [parameter(mandatory=$true, Position=0, HelpMessage="Please provide one or more compurer name")]
        [ValidateNotNullOrEmpty()]
        [validatepattern('(?# Format must be 1 to 63 characters, alphanumeric)^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])$')]
        #Specifies Computer name(s)
           [string[]]$ComputerName
        )
        foreach ($comp in $ComputerName) {
            $os = Get-WmiObject -Class Win32_operatingsystem -ComputerName $comp;
            $cs = Get-WmiObject -Class Win32_computersystem -ComputerName $comp;
            $bios = Get-WmiObject -Class Win32_BIOS -ComputerName $Comp;
            
            #$patch = get-hotfix -computername $ComputerName | select -last 1;
           
            $LastBootUpTime = $os.ConvertToDateTime($os.LastBootUpTime);
            $LocalDateTime = $os.ConvertToDateTime($os.LocalDateTime);
  
            # Calculate uptime - this is automatically a timespan!!!
            $up = $LocalDateTime - $LastBootUpTime;
 
            # Split into Days/Hours/Mins
            $uptime = "$($up.Days) days, $($up.Hours)h, $($up.Minutes)mins";
                        
            $props = [ordered]@{'ComputerName' = $comp;
                       'Uptime' = $uptime;
                       'OSVersion' = $os.version;
                       'SPVersion' = $os.servicepackmajorversion;
                       'Manufacturer' = $cs.manufacturer;
                       'Model' = $cs.model;
                       'RAM' = $cs.Totalphysicalmemory;
                       'BIOSSerial' = $bios.serialnumber;
                       }
            
             $obj = New-Object -TypeName psobject -Property $props
             Write-Output $obj
         
            
            }
        }
 
 
function get-VMRDMInfo {
    [cmdletbinding(PositionalBinding=$false)]
    param (
        [parameter(mandatory=$true, Position=0, HelpMessage="Please provide one or more Virtual Machine name")]
        [ValidateNotNullOrEmpty()]
        [validatepattern('(?# Format must be 1 to 63 characters, alphanumeric)^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])$')]
        #Specifies Virtual Machine name(s)
            [string[]]$ComputerName
        )
        $DiskInfo= @()
        foreach ($VMview in Get-VM $ComputerName | Get-View) {
           
            foreach ($VirtualSCSIController in ($VMView.Config.Hardware.Device | where {$_.DeviceInfo.Label -match "SCSI Controller"})) {
                foreach ($VirtualDiskDevice in ($VMView.Config.Hardware.Device | where {$_.ControllerKey -eq $VirtualSCSIController.Key})) {
                    $VirtualDisk = "" | Select VMname, SCSIController, DiskName, SCSI_ID, DeviceName, DiskFile, DiskSize
                    $VirtualDisk.VMname = $VMview.Name
                    $VirtualDisk.SCSIController = $VirtualSCSIController.DeviceInfo.Label
                    $VirtualDisk.DiskName = $VirtualDiskDevice.DeviceInfo.Label
                    $VirtualDisk.SCSI_ID = "$($VirtualSCSIController.BusNumber) : $($VirtualDiskDevice.UnitNumber)"
                    $VirtualDisk.DeviceName = $VirtualDiskDevice.Backing.DeviceName
                    $VirtualDisk.DiskFile = $VirtualDiskDevice.Backing.FileName
                    $VirtualDisk.DiskSize = $VirtualDiskDevice.CapacityInKB * 1KB / 1GB
                 $DiskInfo += $VirtualDisk
            }
                }
                    }
 
        write-output $DiskInfo | sort VMname, Diskname
                                 
            }