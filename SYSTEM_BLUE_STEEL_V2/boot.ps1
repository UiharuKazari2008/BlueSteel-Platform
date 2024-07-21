Start-Transcript -Path S:\boot.log.txt -Append | Out-Null

$Host.UI.RawUI.WindowTitle = 'BlueSteel 2'
$force_install_mode = $false
$usb_connected = $((Get-Volume -FileSystemLabel SOS_INS -ErrorAction SilentlyContinue | Format-List).Length -gt 0)
$is_admin = $($(whoami) -notlike "*systemuser")
$write_req = $(Test-Path C:\SEGA\update\WRITE_ENABLE -ErrorAction SilentlyContinue)
$admin_req = $(Test-Path C:\SEGA\update\ADMIN_CONSOLE -ErrorAction SilentlyContinue)
$allow_no_locker = $(Test-Path C:\SEGA\ALLOW_NO_BITLOCKER_AND_IM_OK_WITH_THIS -ErrorAction SilentlyContinue)
$allow_no_filter = $(Test-Path C:\SEGA\ALLOW_WRITE_ACCESS_AND_IM_OK_WITH_THIS -ErrorAction SilentlyContinue)
$platform_installed = $(Test-Path -Path "C:\SEGA\system\PLATFORM_INSTALLED" -ErrorAction SilentlyContinue)

$system_ram = ((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB)

Set-Service -Name NVDisplay.ContainerLocalSystem -StartupType Disabled -Confirm:$false -ErrorAction SilentlyContinue

# Detect Emergecy Mode
if ($usb_connected) {
    $letter = (Get-Volume -FileSystemLabel SOS_INS).DriveLetter
    if (Test-Path -Path "${letter}:\BLUE_STEEL\SETUP_MODE" -ErrorAction SilentlyContinue) {
        Write-Host "[!] Enable Admin Mode, Host will enter Admin Mode until file is removed from USB"
        $admin_req = $true
    }
    if (Test-Path -Path "${letter}:\BLUE_STEEL\WRITE_ENABLE" -ErrorAction SilentlyContinue) {
        Write-Host "[!] Enable Write Access, Host will enter R/W Mode until file is removed from USB"
        $write_req = $true
    }
    if (Test-Path -Path "${letter}:\BLUE_STEEL\RESET_PLATFORM" -ErrorAction SilentlyContinue) {
        Write-Host "[!] Enter Platfrom DFU Mode. Host will enter DFU Mode as long as file is on USB"
        Remove-Item -Path "C:\SEGA\system\PLATFORM_INSTALLED" -ErrorAction SilentlyContinue -Force -Confirm:$false
        Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "file commit-delete C:\SEGA\update\PLATFORM_INSTALLED"
    } elseif (Test-Path -Path "${letter}:\BLUE_STEEL\RESET_PLATFORM" -ErrorAction SilentlyContinue) {
        Write-Host "[!] Force Platfrom Enable"
        New-Item -ItemType File -Path "C:\SEGA\system\PLATFORM_INSTALLED" -ItemType File -ErrorAction SilentlyContinue
    }
}

$uwf = $(((Get-WmiObject -class "UWF_Volume" -namespace "root\standardcimv2\embedded") | Where-Object { $_.DriveLetter -eq "C:" } | Select -First 1).Protected -eq "True")

$system_update_found = $false
$src = "C:\SEGA\system\remote_update\"
$password = ""

if ($usb_connected -and (Test-Path -Path "$((Get-Volume -FileSystemLabel SOS_INS).DriveLetter):\*.pack" -ErrorAction SilentlyContinue)) {
    $system_update_found = $true
    $src = "$((Get-Volume -FileSystemLabel SOS_INS).DriveLetter):\"
} elseif (Test-Path -Path "C:\SEGA\system\remote_update\*.pack" -ErrorAction SilentlyContinue) {
    $system_update_found = $true
    $src = "C:\SEGA\system\remote_update\"
}
# Detect Write Filter Enable
if ($allow_no_filter -eq $true) {
    Write-Output "[!] System Write Protection is disabled"
    Write-Output "    Disk Corruption is possible"
} elseif ($allow_no_filter -eq $false -and (Get-WmiObject -class "UWF_Filter" -namespace "root\standardcimv2\embedded").CurrentEnabled -ne $true -and $write_req -eq $false -and $platform_installed) {
    Write-Output "[!] Enable Write Filter!"
    Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "filter enable"
    shutdown /r /t 2 /f /c "Write Filter Enabled"
    Start-Sleep -Seconds 30
} elseif ($uwf -eq $false -and $write_req -eq $true) {
    Write-Output "[!] System Write Protection is pending enable!"
}

# Detect Update to Volume Write Filter
if ($uwf -eq $true -and ($write_req -eq $true -or (Test-Path -Path "C:\SEGA\system\NEW_preboot" -ErrorAction SilentlyContinue) -or $platform_installed -eq $false -or $system_update_found)) {
    Write-Output "[!] Volume Write Protection is requested to be suspended..."
    Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "volume unprotect c:"
    shutdown /r /t 2 /f /c "Write File Suspended"
    Start-Sleep -Seconds 30
} elseif ($uwf -eq $false -and $platform_installed) {
    if (Test-Path -Path "C:\SEGA\system\NEW_preboot" -ErrorAction SilentlyContinue) {
        Remove-Item -Path "C:\SEGA\system\preboot" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
        Move-Item -Path "C:\SEGA\system\NEW_preboot" -Destination "C:\SEGA\system\preboot"
    }
    if ($allow_no_filter -eq $false -and ($write_req -eq $false -and $system_update_found -eq $false)) {
        Write-Output "[!] Volume Write Protection is being enabled..."
        Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "volume protect c:"
        Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "file Add-Exclusion C:\SEGA\update"
        Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "file Add-Exclusion C:\SEGA\system\remote_update"
        shutdown /r /t 2 /f /c "Write File Enabled"
        Start-Sleep -Seconds 30
    }
}

if ($system_update_found) {
    if (Test-Path -Path "${src}SYSTEM_*.pack" -ErrorAction SilentlyContinue) {
        $i = 0
        if (Test-Path -Path "C:\SEGA\update\") {
            Remove-Item -Path "C:\SEGA\update\*" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
        } else {
            New-Item -ItemType Directory -Path "C:\SEGA\update" -Force -Confirm:$false -ErrorAction SilentlyContinue
        }
        Get-ChildItem -Path "${src}SYSTEM_*.pack" | ForEach-Object {
            $i++
            Write-Host "Installing Platform Updates... (${i}/$((Get-ChildItem -Path "${src}SYSTEM_*.pack").Count))"
            &'C:\Program Files\7-Zip\7z.exe' x -aoa -p"${password}" -oC:\SEGA\update "${_}"
            if (Test-Path -Path "C:\SEGA\update\post_update.ps1" -ErrorAction SilentlyContinue) {
                . C:\SEGA\update\post_update.ps1
                Remove-Item -Path "C:\SEGA\update\post_update.ps1" -Force -Confirm:$false -ErrorAction SilentlyContinue
            }
            if ($usb_connected -eq $false) {
                Remove-Item -Path "$_" -Force -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }
    if (Test-Path -Path "${src}OVERLAY_*.pack" -ErrorAction SilentlyContinue) {
        $i = 0
        if (Test-Path -Path "C:\SEGA\temp\") {
            Remove-Item -Path "C:\SEGA\temp\*" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
        } else {
            New-Item -ItemType Directory -Path "C:\SEGA\temp" -Force -Confirm:$false -ErrorAction SilentlyContinue
        }
        Get-ChildItem -Path "${src}OVERLAY_*.pack" | ForEach-Object {
            $i++
            Write-Host "Extracting Overlay Updates... (${i}/$((Get-ChildItem -Path "${src}OVERLAY_*.pack").Count))"
            &'C:\Program Files\7-Zip\7z.exe' x -aoa -p"${password}" -oC:\ "${_}"
            if (Test-Path -Path "C:\SEGA\temp\post_update.ps1" -ErrorAction SilentlyContinue) {
                . C:\SEGA\temp\post_update.ps1
                Remove-Item -Path "C:\SEGA\temp\post_update.ps1" -Force -Confirm:$false -ErrorAction SilentlyContinue
            }
            if ($usb_connected -eq $false) {
                Remove-Item -Path "$_" -Force -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }
    if ((Get-Volume -FileSystemLabel SOS_INS -ErrorAction SilentlyContinue | Format-List).Length -gt 0) {
        Write-Host "`n`n============================================="
        Write-Host " Remove Update USB!"
        Write-Host "============================================="
        While ((Get-Volume -FileSystemLabel SOS_INS -ErrorAction SilentlyContinue | Format-List).Length -gt 0) {
            Sleep -Seconds 1
        }
    }
}

# Detect BitLocker State
if ((Get-BitLockerVolume C:).ProtectionStatus -eq "Off" -and $allow_no_locker -eq $false) {
    Write-Output "[!] BitLocker is not enabled! Applications can not start!"
    Write-Output "    Enable BitLocker or Platform will be erased"
}

# Detect Hardware Type
if (Test-Path -Path "C:\SEGA\system\preboot\preboot.exe" -ErrorAction SilentlyContinue) {
    $model = "ALLS X2"
    if ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1650*") {
        $model = "ALLS HX2.1"
    } elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1660*") {
        $model = "ALLS MX2.1"
    } elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*2070*") {
        $model = "ALLS UX2"
    } elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1050 T*") {
        $model = "ALLS HX2"
    } elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1060*") {
        $model = "ALLS MX2"
    } elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1070*") {
        $model = "ALLS UX"
    } elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1050*") {
        $model = "ALLS HX"
    } elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*750*") {
        $model = "Nu 1.1"
    }
    if ($admin_req -eq $true -or $is_admin -eq $true) {
        Write-Output "[ ] Detected Platform Type: ${model}"
    }
    Set-Content -Encoding utf8 -Value "Model=${model}`nSTEP 1=Boot" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\config.txt"
} else {
    Write-Output "[!] No Platform is installed, Board search skipped!"
}

# Is Admin or Requested Desktop
if ($admin_req -eq $true -or $is_admin -eq $true) {
    Write-Output "Cancel Application Launch, Entering Setup Mode..."
    Start-Process C:\Windows\explorer.exe
    if ($is_admin -eq $false) {
        if ($uwf) {
            Write-Output "[!] Write Protection is Enabled! No modification will be saved on restart"
            Write-Output "== Press [ENTER] to return to Application Mode =="
        } else {
            Write-Output "== Press [ENTER] to return to Application Mode and Lock Volume C:\ =="
        }
        Read-Host
        Remove-Item C:\SEGA\update\ADMIN_CONSOLE -ErrorAction SilentlyContinue
        if (Test-Path -Path "C:\SEGA\system\preboot\preboot.exe" -ErrorAction SilentlyContinue) {
            Remove-Item C:\SEGA\update\WRITE_ENABLE -ErrorAction SilentlyContinue
        }
        if ($uwf) {
            Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "file commit-delete C:\SEGA\update\ADMIN_CONSOLE"
            if (Test-Path -Path "C:\SEGA\system\preboot\preboot.exe" -ErrorAction SilentlyContinue) {
                Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "file commit-delete C:\SEGA\update\WRITE_ENABLE"
            }
        }
        shutdown /r /t 5 /f /c "System Entering Application Mode"
        Start-Sleep -Seconds 30
    }
} elseif ($is_admin -eq $false) {
    Stop-Process -Name preboot -ErrorAction SilentlyContinue
    if (Test-Path -Path "C:\SEGA\update\system_update.ps1" -ErrorAction SilentlyContinue) {
        if ($uwf -eq $true) {
            New-Item -ItemType File -Path "C:\SEGA\update\WRITE_ENABLE"
            Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "file commit C:\SEGA\update\WRITE_ENABLE"
            Write-Output "Volume Write Protection is requested to be suspended..."
            Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "volume unprotect c:"
            shutdown /r /t 2 /f /c "Write File State Change for Platform Update"
            Start-Sleep -Seconds 30
        }
        if ((Get-MpPreference).ExclusionPath -notcontains "C:\SEGA\update\") {
            Add-MpPreference -ExclusionPath "C:\SEGA\update" -ErrorAction SilentlyContinue
        }
        Start-Process -FilePath preboot.exe -Wait -WorkingDirectory "C:\SEGA\system\preboot\"
        if ((Get-MpPreference).ExclusionPath -notcontains "C:\SEGA\update\") {
            Remove-MpPreference -ExclusionPath "C:\SEGA\update" -ErrorAction SilentlyContinue
        }
        shutdown /r /t 0 /f /c "Platform Update Completed"
        Remove-Item C:\SEGA\update\WRITE_ENABLE -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 30
    } elseif ($platform_installed) {
        # System Security Check
        if ($allow_no_filter -eq $false -and $uwf -eq $false) {
            Remove-Item C:\SEGA\update\WRITE_ENABLE -ErrorAction SilentlyContinue
            Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "volume protect c:"
            shutdown /r /t 2 /f /c "Write File Enable"
            Start-Sleep -Seconds 30
        }
    }
    if (((Get-BitLockerVolume C:).ProtectionStatus -eq "On") -or $allow_no_locker -eq $true -or $platform_installed -eq $false) {
        Stop-Service -Name wuauserv -Force -Confirm:$false -ErrorAction SilentlyContinue
        Stop-Service -Name UsoSvc -Force -Confirm:$false -ErrorAction SilentlyContinue
        Stop-Service -Name WaaSMedicSvc -Force -Confirm:$false -ErrorAction SilentlyContinue

        Set-Service -Name wuauserv -StartupType Disabled -Confirm:$false -ErrorAction SilentlyContinue
        Set-Service -Name UsoSvc -StartupType Disabled -Confirm:$false -ErrorAction SilentlyContinue
        Set-Service -Name WaaSMedicSvc -StartupType Disabled -Confirm:$false -ErrorAction SilentlyContinue

        Start-Process -Wait -FilePath C:\SEGA\system\preboot\preboot.exe -WorkingDirectory "C:\SEGA\system\preboot\"
    } else {
        # Violation System Erase    
        Remove-Item -Path "C:\SEGA\system\PLATFORM_INSTALLED" -ErrorAction SilentlyContinue -Force -Confirm:$false
        Start-Process -FilePath uwfmgr.exe -Verb runas -WindowStyle Hidden -Wait -ArgumentList "file commit-delete C:\SEGA\update\WRITE_ENABLE"
        Remove-Item -Path "S:\*" -Recurse -Force -Confirm:$false
    }
    shutdown /r /t 10 /f /c "System Watchdog Failure"
    Sleep -Seconds 30
}
# SIG # Begin signature block
# MIIGEgYJKoZIhvcNAQcCoIIGAzCCBf8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzuq7ilnMsmcMzoRG5AL/erQH
# +dugggOCMIIDfjCCAmagAwIBAgIQJlq0EDKWmKtOwveGVRLWsTANBgkqhkiG9w0B
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
# BgkqhkiG9w0BCQQxFgQU3i7CLKTaQiJIchQn220H8EV47lMwDQYJKoZIhvcNAQEB
# BQAEggEAH0q2ylzxzAx5HQNcGoKUDrMWWCcrtRy4az/oXxuRM4JHCgIarSLRqCIw
# kdP+ROxHBU/vh5xyYdEwgCYjp4nZv1xGFoatskvJqZFV11g070V3eBfOm66GikVI
# ykOVA2QvL0U8cMgloz/PHnVb3GoU8o4p0wUmxS1uhRjlSxAVAb86/1AXp83BUCD8
# MUockUG8xtl1sKILN50Nw5e/ZV6Ise2e3davWuHzSsuPMetm8eWSHvX/LkODi8Ie
# 3L+1/NS5w3gHUaVhta8t5sBHsyJSu/PqMNWQfOLC6n0QK7HPAgFNs405OiZywslG
# HrAC9Dg5Inuxu9LOe2WQCC3OAByBIQ==
# SIG # End signature block
