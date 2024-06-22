$snap_disk = (Get-VM -Name "Ars Nova Base Image 2 (EFI)" | Get-VMCheckpoint | Sort-Object -Property CreationTime -Descending | Select-Object -First 1 | Get-VMHardDiskDrive -ControllerNumber 0 -ControllerLocation 0)
$disk = Mount-DiskImage -ImagePath $snap_disk.Path -Access ReadOnly
$id = $disk.DevicePath
#$DiskDrives = (Gwmi Win32_diskdrive | select DeviceID,BytesPerSector,Index,Caption,InterfaceType,Size,TotalSectors,SerialNumber | Out-GridView -OutputMode Multiple -Title 'Select Source Drive(s)').DeviceID
& "C:\Program Files\Git\usr\bin\dd.exe" if=$id of='H:\Blue Steel OS v2\base.img' bs=4M
Dismount-DiskImage -ImagePath $snap_disk.Path