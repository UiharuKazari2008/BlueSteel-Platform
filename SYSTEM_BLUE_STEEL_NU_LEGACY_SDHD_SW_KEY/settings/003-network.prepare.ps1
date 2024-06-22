function New-LoopbackAdapter {
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    [CmdLetBinding()]
    param
    (
        [Parameter(
            Mandatory=$true,
            Position=0)]
        [string]
        $Name,
        
        [switch]
        $Force
    )
    $null = $PSBoundParameters.Remove('Name')

    # Check for the existing Loopback Adapter
    $Adapter = Get-NetAdapter `
        -Name $Name `
        -ErrorAction SilentlyContinue

    # Is the loopback adapter installed?
    if ($Adapter)
    {
        Throw "A Network Adapter $Name is already installed."
    } # if

    # Make sure DevCon is installed.
    $DevConExe = "C:\SEGA\system\devcon64.exe"

    # Get a list of existing Loopback adapters
    # This will be used to figure out which adapter was just added
    $ExistingAdapters = (Get-LoopbackAdapter).PnPDeviceID

    # Use Devcon.exe to install the Microsoft Loopback adapter
    # Requires local Admin privs.
    $null = & $DevConExe @('install',"$($ENV:SystemRoot)\inf\netloop.inf",'*MSLOOP')

    # Find the newly added Loopback Adapter
    $Adapter = Get-NetAdapter `
        | Where-Object {
            ($_.PnPDeviceID -notin $ExistingAdapters ) -and `
            ($_.DriverDescription -eq 'Microsoft KM-TEST Loopback Adapter')
        }
    if (-not $Adapter)
    {
        Throw "The new Loopback Adapter was not found."
    } # if

    # Rename the new Loopback adapter
    $Adapter | Rename-NetAdapter `
        -NewName $Name `
        -ErrorAction Stop

    # Set the metric to 254
    Set-NetIPInterface `
        -InterfaceAlias $Name `
        -InterfaceMetric 254 `
        -ErrorAction Stop

    # Wait till IP address binding has registered in the CIM subsystem.
    # if after 30 seconds it has not been registered then throw an exception.
    [Boolean] $AdapterBindingReady = $false
    [DateTime] $StartTime = Get-Date
    while (-not $AdapterBindingReady `
        -and (((Get-Date) - $StartTime).TotalSeconds) -lt 30)
    {
        try
        {
            $IPAddress = Get-CimInstance `
                -ClassName MSFT_NetIPAddress `
                -Namespace ROOT/StandardCimv2 `
                -Filter "((InterfaceAlias = '$Name') AND (AddressFamily = 2))" `
                -ErrorAction Stop
            if ($IPAddress)
            {
                $AdapterBindingReady = $true
            } # if
            Start-Sleep -Seconds 1
        }
        catch
        {
        }
    } # while

    if (-not $IPAddress)
    {
        Throw "The New Loopback Adapter was not found in the CIM subsystem."
    }

    # Pull the newly named adapter (to be safe)
    $Adapter = Get-NetAdapter `
        -Name $Name `
        -ErrorAction Stop

    Return $Adapter
}
$found_seganet = ((Get-NetAdapter | Where { $_.Name -ne 'CabinetLink' -and $_.Status -eq "Up" -and $_.Virtual -eq $False } | Get-NetIPAddress -ErrorAction SilentlyContinue | Where { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -like "192.168.139.*" } | Measure-Object -Line).Lines -gt 0)
if ((Test-Path -Path "S:\SDHD\ENABLE_HARUNA_NETWORK") -and $found_seganet -eq $false) {
    if ((Get-NetAdapter -Name "CabinetLink" -ErrorAction SilentlyContinue | Measure-Object -Line).Lines -lt 1) {
        New-LoopbackAdapter -Name "CabinetLink" -ErrorAction SilentlyContinue -Force
    }
    netsh interface ipv4 add address "CabinetLink" 192.168.139.11 255.255.255.0 store=active
    netsh interface ipv4 add address "CabinetLink" 192.168.139.12 255.255.255.0 store=active
    netsh interface ipv4 add address "CabinetLink" 192.168.139.13 255.255.255.0 store=active
    netsh interface ipv4 add address "CabinetLink" 192.168.139.14 255.255.255.0 store=active
}
# SIG # Begin signature block
# MIIGEgYJKoZIhvcNAQcCoIIGAzCCBf8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7XsYANx8e9siJXaGGjt3nD6b
# +iegggOCMIIDfjCCAmagAwIBAgIQJlq0EDKWmKtOwveGVRLWsTANBgkqhkiG9w0B
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
# BgkqhkiG9w0BCQQxFgQUIF3Lsq6PxEj521PKnwMB/DKpCFwwDQYJKoZIhvcNAQEB
# BQAEggEAGMAS6Y6Uj7aZMM+VcFbxfP5DGAWlrTQo+AS1749iRGGnAMoiISOog083
# 43LfuZ8TPq9KSR2kylCI+J4w/Vpqzy22tSk0ChC0Eosp0rPoZH291GLVXW1MqCtv
# vRKx3YSKxDFvv6bRDx+SON1Y0k2bvVHa7cFpo9f5IlJwRKG84NTqQOxMdHTRF2/5
# GaT2juAYdjf0WqskMT+p2Fqrg62Dc61Cli4acuOhgPgxavuuHLWU5OOO+DwinqON
# REM9KW4kZ071gexLZ78a8k2JaSRrdoG0A5sInSiPRLzTdXRwBnWfjY864fAxXVRP
# 4dJvPGv9cTQPuBIAgTxA3pk37RvQEA==
# SIG # End signature block
