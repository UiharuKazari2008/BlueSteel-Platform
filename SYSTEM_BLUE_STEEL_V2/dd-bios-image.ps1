$snap_disk = (Get-VM -Name "Ars Nova Base Image 2 (BIOS)" | Get-VMCheckpoint | Sort-Object -Property CreationTime -Descending | Select-Object -First 1 | Get-VMHardDiskDrive -ControllerNumber 0 -ControllerLocation 0)
$disk = Mount-DiskImage -ImagePath $snap_disk.Path -Access ReadOnly
$id = $disk.DevicePath
& "C:\Program Files\Git\usr\bin\dd.exe" if=$id of='H:\Blue Steel OS v2\nu-base.img' bs=1M status=progress
Dismount-DiskImage -ImagePath $snap_disk.Path