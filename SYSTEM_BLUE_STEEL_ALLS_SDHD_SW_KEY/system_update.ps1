Start-Transcript -Path S:\system.update.log.txt -Append | Out-Null
$allow_no_locker = $(Test-Path C:\SEGA\ALLOW_NO_BITLOCKER_AND_IM_OK_WITH_THIS -ErrorAction SilentlyContinue)
$system_ram = ((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB)

Write-Host "BLUE STEEL Platform Upgrade"
Write-Host "----------------------------------"

cd "C:\SEGA\update\"

if (Test-Path -Path "C:\SEGA\system\VERSION" -ErrorAction SilentlyContinue) {
    Set-Content -Encoding utf8 -Value "Check and Repair ROM" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
    Sleep -Seconds 2
    Repair-Volume -DriveLetter S -OfflineScanAndFix -ErrorAction SilentlyContinue

    if ((Get-BitLockerVolume -MountPoint C:).ProtectionStatus -eq "Off" -and $allow_no_locker -eq $false) {
	    Set-Content -Encoding utf8 -Value "Encrypt ROM" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
	    Sleep -Seconds 2
	    Enable-BitLocker -MountPoint C: -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector -Confirm:$false -ErrorAction Stop -SkipHardwareTest
        New-Item -ItemType File -Path C:\SEGA\.delay-restart

        While ((Get-BitLockerVolume -MountPoint C:).EncryptionPercentage -ne 100) {
            Set-Content -Encoding utf8 -Value "Encrypt ROM $((Get-BitLockerVolume -MountPoint C:).EncryptionPercentage)%" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }
    }

    Set-Content -Encoding utf8 -Value "Expand Substorage" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
    Resize-Partition -DiskNumber (Get-Partition -DriveLetter S).DiskNumber -PartitionNumber (Get-Partition -DriveLetter S).PartitionNumber -Size (Get-PartitionSupportedSize -DiskNumber (Get-Partition -DriveLetter S).DiskNumber -PartitionNumber (Get-Partition -DriveLetter S).PartitionNumber).SizeMax  -ErrorAction SilentlyContinue
}

if ($system_ram -lt 8) { 
    Set-Content -Encoding utf8 -Value "Setup Pagefile" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
    Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{
        Name = "S:\pagefile.sys"
        InitialSize = 2048
        MaximumSize = 8096
    }
    Get-WmiObject -Class Win32_PageFileSetting | Where-Object { $_.Name -like "S:\pagefile.sys" } | Set-WmiInstance -Arguments @{
        InitialSize = 2048
        MaximumSize = 8096
    }
}

Set-Content -Encoding utf8 -Value "Update ROM" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
Copy-Item -Path "C:\SEGA\update\init_SDHD\init_start.ps1" -Destination "C:\SEGA\system\init_start.ps1" -Force -Confirm:$false -ErrorAction SilentlyContinue
Stop-Process -Name sgxsegaboot -Force -ErrorAction SilentlyContinue
Copy-Item -Force -Path "C:\SEGA\update\sgxsegaboot.exe" -Destination "C:\SEGA\system\new.sgxsegaboot.exe" -ErrorAction SilentlyContinue
Copy-Item -Force -Path "C:\SEGA\update\sgxinithandle.exe" -Destination "C:\SEGA\system\sgxinithandle.exe" -ErrorAction SilentlyContinue

Set-Content -Encoding utf8 -Value "Update Bootloader" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
Move-Item -Force -Path "C:\SEGA\update\preboot" -Destination "C:\SEGA\system\NEW_preboot"

if ((Test-Path -Path "C:\SEGA\system\VERSION" -ErrorAction SilentlyContinue) -eq $false) {
    Set-Content -Value "2.1" -Path "C:\SEGA\system\VERSION" -ErrorAction SilentlyContinue
    shutdown /f /r /t 5 /c "Base Version Update (V2.0 => V2.1) - Restart Required!"
    Start-Sleep -Seconds 30
} elseif (Test-Path -Path "C:\SEGA\system\platform_update\" -ErrorAction SilentlyContinue) {
    Set-Content -Encoding utf8 -Value "Remove Prev. Bootloader" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\SEGA\system\platform_update" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
}

Set-Content -Encoding utf8 -Value "Install Keychip Driver" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
Remove-Item -Path "C:\SEGA\system\savior_of_song_keychip.exe" -Recurse -Confirm:$false -Force -ErrorAction SilentlyContinue
Move-Item -Force -Path "C:\SEGA\update\savior_of_song_keychip.exe" -Destination "C:\SEGA\system\savior_of_song_keychip.exe"
Remove-Item -Path "C:\SEGA\system\savior_of_song_patcher.exe" -Recurse -Confirm:$false -Force -ErrorAction SilentlyContinue
Move-Item -Force -Path "C:\SEGA\update\savior_of_song_patcher.exe" -Destination "C:\SEGA\system\savior_of_song_patcher.exe"

Set-Content -Encoding utf8 -Value "Configuration Keychip" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
if ((Test-Path -Path "C:\SEGA\system\settings\SDHD\auth.keychip.ps1" -ErrorAction SilentlyContinue) -and (Test-Path -Path "C:\SEGA\update\settings\auth.keychip.ps1" -ErrorAction SilentlyContinue) -eq $false) {
    Copy-Item -Force -Path "C:\SEGA\system\settings\SDHD\auth.keychip.ps1" -Destination "C:\SEGA\update\settings\auth.keychip.ps1" -ErrorAction SilentlyContinue
}
Remove-Item -Path "C:\SEGA\system\settings\SDHD\" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\SEGA\system\applications\SDHD\" -Recurse -Force -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Path "C:\SEGA\system\settings\" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "C:\SEGA\system\settings\SDHD\" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "C:\SEGA\system\applications\" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "C:\SEGA\system\applications\SDHD\" -ErrorAction SilentlyContinue

Copy-Item -Path "C:\SEGA\update\settings\*" -Destination "C:\SEGA\system\settings\SDHD\" -Force -Confirm:$false -ErrorAction SilentlyContinue
Copy-Item -Path "C:\SEGA\update\init_SDHD\start.ps1" -Destination "C:\SEGA\system\applications\SDHD\start.ps1" -Force -Confirm:$false -ErrorAction SilentlyContinue
Copy-Item -Path "C:\SEGA\update\init_SDHD\prepare.ps1" -Destination "C:\SEGA\system\applications\SDHD\prepare.ps1" -Force -Confirm:$false -ErrorAction SilentlyContinue
Copy-Item -Path "C:\SEGA\update\init_SDHD\enviorment.ps1" -Destination "C:\SEGA\system\applications\SDHD\enviorment.ps1" -Force -Confirm:$false -ErrorAction SilentlyContinue

if ((Test-Path -Path "S:\SDHD\app.vhd" -ErrorAction SilentlyContinue) -eq $false -or (Test-Path -Path "C:\SEGA\system\remote_update\{{ Format System }}" -ErrorAction SilentlyContinue)) {
    Set-Content -Encoding utf8 -Value "Format Substorage" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
    Remove-Item -Path S:\SDHD\ -Recurse -Force -ErrorAction SilentlyContinue

    Set-Content -Encoding utf8 -Value "Install Bookcase" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path "S:\SDHD\" -ErrorAction SilentlyContinue
    Move-Item -Force -Path "C:\SEGA\update\bookcase_SDHD\*" -Destination "S:\SDHD\"
}

Set-Content -Encoding utf8 -Value "Install Device Driver(s)" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
#Get-ChildItem -Path "C:\SEGA\update\drivers\display\" | ForEach-Object {
#    & pnputil.exe -i -a $_.FullName
#}
#Get-ChildItem -Path "C:\SEGA\update\drivers\audio\" | ForEach-Object {
#    & pnputil.exe -i -a $_.FullName
#}
#& pnputil.exe /remove-device /class display
#& pnputil.exe /remove-device /class audioendpoint
#& pnputil.exe /remove-device /class media
#& pnputil.exe /scan-devices

Set-Content -Encoding utf8 -Value "Install Haruna Network Driver" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
Remove-Item -Path "C:\SEGA\system\devcon64.exe" -Force -Confirm:$false -ErrorAction SilentlyContinue
Copy-Item -Path "C:\SEGA\update\devcon64.exe" -Destination "C:\SEGA\system\devcon64.exe" -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path "C:\SEGA\system\haruna_network.exe" -Force -Confirm:$false -ErrorAction SilentlyContinue
Copy-Item -Path "C:\SEGA\update\haruna_network.exe" -Destination "C:\SEGA\system\haruna_network.exe" -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path "C:\SEGA\system\HarunaOverlay" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
Copy-Item -Path "C:\SEGA\update\HarunaOverlay" -Recurse -Destination "C:\SEGA\system\HarunaOverlay" -Force -Confirm:$false -ErrorAction SilentlyContinue

if ((Get-ChildItem -Path C:\SEGA\system\vpn\bin\ -ErrorAction SilentlyContinue).Count -lt 2) {
    Set-Content -Encoding utf8 -Value "Install VPN Network Driver" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
    Add-MpPreference -ControlledFolderAccessAllowedApplications "C:\Windows\System32\msiexec.exe" -ErrorAction SilentlyContinue
    msiexec /i C:\SEGA\update\vpn-server.msi PRODUCTDIR="C:\SEGA\system\vpn\" ADDLOCAL=OpenVPN.Service,OpenVPN,Drivers,Drivers.TAPWindows6 /norestart /passive
    Sleep -Seconds 1
    While ((Get-ChildItem -Path C:\SEGA\system\vpn\bin\ -ErrorAction SilentlyContinue).Count -lt 2) { Sleep -Seconds 1 }
    Sleep -Seconds 8
}

if (Test-Path -Path "C:\SEGA\update\*.ovpn" -ErrorAction SilentlyContinue) {
    Copy-Item -Force -Path "C:\SEGA\update\*.ovpn" -Destination "C:\SEGA\system\vpn\config-auto\" -ErrorAction SilentlyContinue
}

Set-Content -Encoding utf8 -Value "Configure Firewall" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
Start-Process -WindowStyle Hidden -FilePath "C:\Windows\system32\reg.exe" -ArgumentList "IMPORT `"C:\SEGA\update\netprofile.reg`""
if ((Get-NetFirewallRule -Name "Network Driver - Haruna" -ErrorAction SilentlyContinue | Measure-Object -Line).Lines -eq 0) {
    $rule = New-NetFirewallRule -DisplayName "Network Driver - Haruna" -Direction Inbound -Program "C:\SEGA\system\haruna_network.exe" -Action Allow -ErrorAction SilentlyContinue
    if ($rule.PrimaryStatus -ne "OK") {
        Set-Content -Encoding utf8 -Value "Firewall 1 Rule Failure" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 10
    }
}
if ((Get-NetFirewallRule -Name "Application - SDHD" -ErrorAction SilentlyContinue | Measure-Object -Line).Lines -eq 0) {
    $rule = New-NetFirewallRule -DisplayName "Application - SDHD" -Direction Inbound -Program "X:\bin\chusanApp.exe" -Action Allow -ErrorAction SilentlyContinue
    if ($rule.PrimaryStatus -ne "OK") {
        Set-Content -Encoding utf8 -Value "Firewall 2 Rule Failure" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 10
    }
}

Set-Content -Encoding utf8 -Value "Prepare Security" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue
Import-Certificate -FilePath "C:\SEGA\update\code_sign.cer" -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
Import-Certificate -FilePath "C:\SEGA\update\code_sign.cer" -CertStoreLocation Cert:\LocalMachine\Root
Add-MpPreference -ControlledFolderAccessAllowedApplications "C:\SEGA\system\savior_of_song_keychip.exe" -ErrorAction SilentlyContinue
Add-MpPreference -ControlledFolderAccessAllowedApplications "C:\SEGA\system\preboot\preboot.exe" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath X:\data\ -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath Z:\ -ErrorAction SilentlyContinue
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Force -Confirm:$false
Set-Service -Name NVDisplay.ContainerLocalSystem -StartupType Disabled -Confirm:$false -ErrorAction SilentlyContinue
Set-Service -Name wuauserv -StartupType Disabled -Confirm:$false -ErrorAction SilentlyContinue
Set-Service -Name UsoSvc -StartupType Disabled -Confirm:$false -ErrorAction SilentlyContinue

if ($system_ram -ge 8) { 
    & uwfmgr overlay set-size 4096
    & uwfmgr overlay set-criticalthreshold 4000
} elseif ($system_ram -ge 4) { 
    & uwfmgr overlay set-size 2048
    & uwfmgr overlay set-criticalthreshold 2000
} else {
    & uwfmgr overlay set-size 1024
    & uwfmgr overlay set-criticalthreshold 1000
}
& uwfmgr file add-exclusion "C:\Windows\wlansvc\Policies"
& uwfmgr registry add-exclusion "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\wlansvc"
& uwfmgr file add-exclusion "C:\ProgramData\Microsoft\wlansvc\Profiles\Interfaces"
& uwfmgr registry add-exclusion "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Wlansvc"
& uwfmgr registry add-exclusion "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\WwanSvc"
& uwfmgr file add-exclusion "C:\Windows\System32\winevt\Logs"
& uwfmgr file add-exclusion "C:\Windows\assembly"

Set-Service -Name wuauserv -StartupType Disabled
Stop-Service -Name wuauserv -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Value 4
Stop-Service -Name WaaSMedicSvc -Force
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue

Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue

New-Item -Path "C:\SEGA\system\PLATFORM_INSTALLED" -ItemType File -ErrorAction SilentlyContinue

if ((Get-Volume -FileSystemLabel SOS_INS -ErrorAction SilentlyContinue | Format-List).Length -gt 0) {
    Set-Content -Encoding utf8 -Value "Disconnect Update USB!" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt"
    While ((Get-Volume -FileSystemLabel SOS_INS -ErrorAction SilentlyContinue | Format-List).Length -gt 0) {
        Sleep -Seconds 1
    }
}

Set-Content -Encoding utf8 -Value "Update Installed" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt" -ErrorAction SilentlyContinue

# SIG # Begin signature block
# MIIGEgYJKoZIhvcNAQcCoIIGAzCCBf8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3u26X8N6q4U8nqVjgyoc8VrD
# zVagggOCMIIDfjCCAmagAwIBAgIQJlq0EDKWmKtOwveGVRLWsTANBgkqhkiG9w0B
# AQUFADBFMUMwQQYDVQQDDDpDb2RlIFNpZ25pbmcgLSBBY2FkZW15IENpdHkgUmVz
# ZWFyY2ggUC5TLlIuIChmb3IgTWlzc2xlc3MpMB4XDTIzMTIyOTIzMTMzNVoXDTMw
# MTIyNDA1MDAwMFowRTFDMEEGA1UEAww6Q29kZSBTaWduaW5nIC0gQWNhZGVteSBD
# aXR5IFJlc2VhcmNoIFAuUy5SLiAoZm9yIE1pc3NsZXNzKTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBANqtipcPEhVWQAUz+KVOBm806ZX0LVp/DV/AW2yJ
# VlBcmT4WP8cIEIay4jU3QZCoVYztQnxI6VUgXsxrpgVfdmWv7Mi1T0yESaicB56k
# c+E+SuJ5QPJiNEOom1cFhpriafjIwjcXazBP1RfqzqP7yfEbN3CxSp4jpRHCfIbq
# agYyVjDqMnyk4iXh2oOY19OHCmHqKCZ0jRlDLpU2RCVMEV0pNewq7O2wn745NxF2
# cm4FP4CU48Zav2LJDwlI2ZA0j5xVJKnwLhRhde0A+N6oFG5GWP709lW9A2EY4tIV
# GKX+FH6BwnXCAedWoiHMa55m0u1KGfxUJc1wC6fnFzEa5mECAwEAAaNqMGgwDgYD
# VR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMCIGA1UdEQQbMBmCF2Js
# dWUtc3RlZWwubWlzc2xlc3MubmV0MB0GA1UdDgQWBBSQo+sgAwlIIYWIsEVsvXgF
# dUTz0DANBgkqhkiG9w0BAQUFAAOCAQEAC8jrcbhyQLn2ddfFn2cRk4ONXdp7EDbE
# Eqr+OifivDuUwK5hV2ds9ygbvcuYK2hv1wrixTVElIvQ40qXzSPtbSwlQ86OCGWc
# hrnnI04iAMKFq8m3rxVrePe0rGwJk/NcIXORRQbU8H3yI2UEMAOqCXr8CGcJyxer
# n9jLCxIBQXf8nJ9GU7GydDn/ODFdqCKUhbPAlMCQC4kdQMLPc+6XYnlQ6ex2qSPq
# MT5Josy660b+bUb+PrvhOEG5TH2MP+SCq9hQJZ3viv/ciG1c5x6WnW2HU6WM7XC1
# HKt1v5NZCaCwDD1n0v4RqIODI0Qk9eqmD+45rkrQdZHRZuhwgmBASTGCAfowggH2
# AgEBMFkwRTFDMEEGA1UEAww6Q29kZSBTaWduaW5nIC0gQWNhZGVteSBDaXR5IFJl
# c2VhcmNoIFAuUy5SLiAoZm9yIE1pc3NsZXNzKQIQJlq0EDKWmKtOwveGVRLWsTAJ
# BgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAj
# BgkqhkiG9w0BCQQxFgQUFlqAWJJdzjhp9hJ5TSxsvclJvdwwDQYJKoZIhvcNAQEB
# BQAEggEAf+7ySpgULnBilg4QeJE9YuL8gtLvo4xiCZMLcqs4fgI5yihgwhePQO8S
# /71kygw7+spchxYQSqs+ulf2DxHbrAH2xBKHXWCOWucskF7UULSCJM9mXw0eoFOa
# QOemDHM1xMdeT8HiL2Nqnshf3m6Rlv1m/2xsweKJ7fjeVGw3B8FO5lz80E3o5fcx
# kFp493Ee3G539ca4vETPkPk5kCoVepfefTG6YWSZw+tYjZtajSF7snflzbor67my
# ZfX40LSpflUF5OkEtOYUzlQ9f1hC+6H2dAX73ynbj7D+NYPjjg/OT031ty2w0iwl
# +6FwotJ8Q3htjgrViCHYQYueP0W3YQ==
# SIG # End signature block
