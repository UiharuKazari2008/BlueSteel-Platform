if (Test-Path "C:\SEGA\system\savior_of_song_keychip.exe") {
    Repair-Volume -DriveLetter S -OfflineScanAndFix -ErrorAction SilentlyContinue
    if (((Get-Volume -FileSystemLabel SOS_INS -ErrorAction SilentlyContinue | Format-List).Length -gt 0) -or ((Get-ChildItem -Path "C:\SEGA\system\remote_update" -ErrorAction SilentlyContinue).Count -gt 0)) {
        . .\enviorment.ps1
        if ((Get-ChildItem -Path "C:\SEGA\system\remote_update" -ErrorAction SilentlyContinue).Count -gt 0) {
            Set-Content -Encoding utf8 -Value "Update Pending!" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt"
        } else {
            Set-Content -Encoding utf8 -Value "Do not remove the update USB!" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\install.txt"
        }
        Start-Process -Wait -WindowStyle Hidden -FilePath "C:\SEGA\system\savior_of_song_keychip.exe" -ArgumentList "${keychip_config} --update"
        if (Test-Path -Path "C:\SEGA\update\system_update.ps1" -ErrorAction SilentlyContinue) {
            Set-Content -Encoding utf8 -Value "STEP 31=Reboot System=false`nerror=false" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\state.txt"
        } else {
            Set-Content -Encoding utf8 -Value "STEP 31=Reloading=false`nerror=false" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\state.txt"
        }
    }

    if (Test-Path -Path "C:\SEGA\update\system_update.ps1" -ErrorAction SilentlyContinue) {
      Stop-Process -Name preboot -ErrorAction SilentlyContinue
      shutdown /t 2 /f /r /c "Reboot Required"
      Sleep -Seconds 15
    } else {
      . .\enviorment.ps1
      Start-Process -Wait -WindowStyle Hidden -FilePath "C:\SEGA\system\savior_of_song_keychip.exe" -ArgumentList "${keychip_config}"
    }
} else {
    Set-Content -Encoding utf8 -Value "STEP 31=Reloading=false`nerror=true`nerrorno=ERROR 0700`nerrormessage=Keychip Driver Missing`n" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\state.txt" -ErrorAction SilentlyContinue
}
# SIG # Begin signature block
# MIIGEgYJKoZIhvcNAQcCoIIGAzCCBf8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUius7aN854Wf2SrIlWvGOqD5Z
# POqgggOCMIIDfjCCAmagAwIBAgIQJlq0EDKWmKtOwveGVRLWsTANBgkqhkiG9w0B
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
# BgkqhkiG9w0BCQQxFgQUZy0f2lBcARqEQsl7l673u1C1su0wDQYJKoZIhvcNAQEB
# BQAEggEAPgRNE3zxcHqn6fixjCHFIlYbTpMyWDGHvOGRJ4qJ6/9Hp49JLq7/6XRe
# F9gvpXgBskFWCykVL6Nej/o/LY7MCy07gLArXG7/HtA/sADGhoiRZMV8o6R/1MGD
# IQ6IwVDZbvgwqd2JUPdUjU+ujGzQZ5zC+8sz30kLvkOQWJE3GQyOKElfmZ+cQpHZ
# F3LNCb7gMkthVdxII9KnyEtQJX2FIK7Mdj/vfWketoOKlZOC2YG7M4AZusWlWilK
# +K022IWz1qPuzjF5O1DrI69DBxTj6azVMcMOPd3UWTcXpO/SzrvR4nHa3ccv9UiM
# cmPfB8Fx/mFr/I6WkhbMiPi7psFuUA==
# SIG # End signature block
