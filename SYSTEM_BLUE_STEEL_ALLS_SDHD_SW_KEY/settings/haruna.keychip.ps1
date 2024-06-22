$found_seganet = ((Get-NetAdapter | Where { $_.Name -ne 'CabinetLink' -and $_.Status -eq "Up" -and $_.Virtual -eq $False } | Get-NetIPAddress -ErrorAction SilentlyContinue | Where { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -like "192.168.139.*" } | Measure-Object -Line).Lines -gt 0)
if ((Test-Path -Path "S:\SDHD\ENABLE_HARUNA_NETWORK") -and $found_seganet -eq $false) {
    $keychip_config = "${keychip_config} --networkDriver `"C:\SEGA\system\haruna_network.exe`" --networkConfig `"Y:\net_config.json`""
    
    if ((Test-Path -Path "C:\SEGA\system\HarunaOverlay\HarunaOverlay.exe" -ErrorAction SilentlyContinue) -and (Test-Path -Path "S:\SDHD\ENABLE_HARUNA_OVERLAY")) {
        $keychip_config = "${keychip_config} --networkOverlay `"C:\SEGA\system\HarunaOverlay\HarunaOverlay.exe`""
    }
    if (Test-Path -Path "C:\SEGA\system\applications\SDHD\net_prepare.ps1") {
        $keychip_config = "${keychip_config} --netPrepScript net_prepare.ps1"
    }
    if (Test-Path -Path "C:\SEGA\system\applications\SDHD\net_cleanup.ps1") {
        $keychip_config = "${keychip_config} --cleanupScript net_cleanup.ps1"
    }
} elseif ($found_seganet) {
    $suffix = $((Get-NetAdapter | Where { $_.Name -ne 'CabinetLink' -and $_.Status -eq "Up" -and $_.Virtual -eq $False } | Get-NetIPAddress -ErrorAction SilentlyContinue | Where { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -like "192.168.139.*" } | Select -First 1).IPAddress.split(".") | Select -Last 1)
    $keychip_config = "${keychip_config} --networkDirect `"${suffix}`""
}
# SIG # Begin signature block
# MIIGEgYJKoZIhvcNAQcCoIIGAzCCBf8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJXINDenhuu5rVn34yi8bBtrR
# C56gggOCMIIDfjCCAmagAwIBAgIQJlq0EDKWmKtOwveGVRLWsTANBgkqhkiG9w0B
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
# BgkqhkiG9w0BCQQxFgQUEnKH5ymx+LdurcyLq11Yp/NWC/MwDQYJKoZIhvcNAQEB
# BQAEggEAUMP+KY67b2fCLqEukDh3fGnSRnKkfvjK/Dbei5y61m0VP0sU9R1t22vf
# QipXMjU4TBlQIj8rs/sOrEt1jSl2KFi8+Ik33zIfv0mC7dwoitfLHr2d+C3iyPcn
# suPX4HpGmkoQHfQS/3QzM6UjY4c/dBB3iHLJ237jjHuODg4x1JpvDyQjhnFn0/Bg
# kZHuGJ8ZoJybGvtQ2/wtHAjx2vZ7d5vtp66wfVORipbtXsjyonks0eiRNnSvw0n9
# qkLDARBJUIsdsApFnsfixuQdyCbHH0bTLdtWLK5o/maSHDn2HVS6EyHJU9o+rMOl
# ikegmKy6vjODsjdGB4DbdPGfxk6GgA==
# SIG # End signature block
