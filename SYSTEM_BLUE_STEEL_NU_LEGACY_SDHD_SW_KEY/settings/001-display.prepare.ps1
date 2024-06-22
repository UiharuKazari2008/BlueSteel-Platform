#$is_sp_approved = $true
#$is_config_warning = $false
#if ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1050 T*") {
#    $is_sp_approved = $false
#} elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1060*") {
#    $is_sp_approved = $false
#} elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1070*") {
#    $is_sp_approved = $false
#    $is_config_warning = "Hardware Config: GPU is not approved for SP Mode"
#} elseif ((Get-WmiObject win32_videocontroller | Where { $_.Status -eq 'OK' -and $_.Availability -eq 3 } | Select -Last 1).Description -like "*1050*") {
#    $is_sp_approved = $false
#} else {
#    $is_config_warning = "Hardware Config: GPU is not approved for SP Mode"
#}

Function Set-ScreenResolution {
<# 
    .Synopsis 
        Sets the Screen Resolution of the primary monitor 
    .Description 
        Uses Pinvoke and ChangeDisplaySettings Win32API to make the change 
    .Example 
        Set-ScreenResolution -Width 1024 -Height 768    -Freq 60         
    #> 
param ( 
[Parameter(Mandatory=$true, 
           Position = 0)] 
[int] 
$Width, 
 
[Parameter(Mandatory=$true, 
           Position = 1)] 
[int] 
$Height, 

[Parameter(Mandatory=$true, 
           Position = 2)] 
[int] 
$Freq
) 
 
$pinvokeCode = @" 
 
using System; 
using System.Runtime.InteropServices; 
 
namespace Resolution 
{ 
 
    [StructLayout(LayoutKind.Sequential)] 
    public struct DEVMODE1 
    { 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmDeviceName; 
        public short dmSpecVersion; 
        public short dmDriverVersion; 
        public short dmSize; 
        public short dmDriverExtra; 
        public int dmFields; 
 
        public short dmOrientation; 
        public short dmPaperSize; 
        public short dmPaperLength; 
        public short dmPaperWidth; 
 
        public short dmScale; 
        public short dmCopies; 
        public short dmDefaultSource; 
        public short dmPrintQuality; 
        public short dmColor; 
        public short dmDuplex; 
        public short dmYResolution; 
        public short dmTTOption; 
        public short dmCollate; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmFormName; 
        public short dmLogPixels; 
        public short dmBitsPerPel; 
        public int dmPelsWidth; 
        public int dmPelsHeight; 
 
        public int dmDisplayFlags; 
        public int dmDisplayFrequency; 
 
        public int dmICMMethod; 
        public int dmICMIntent; 
        public int dmMediaType; 
        public int dmDitherType; 
        public int dmReserved1; 
        public int dmReserved2; 
 
        public int dmPanningWidth; 
        public int dmPanningHeight; 
    }; 
 
 
 
    class User_32 
    { 
        [DllImport("user32.dll")] 
        public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode); 
        [DllImport("user32.dll")] 
        public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags); 
 
        public const int ENUM_CURRENT_SETTINGS = -1; 
        public const int CDS_UPDATEREGISTRY = 0x01; 
        public const int CDS_TEST = 0x02; 
        public const int DISP_CHANGE_SUCCESSFUL = 0; 
        public const int DISP_CHANGE_RESTART = 1; 
        public const int DISP_CHANGE_FAILED = -1; 
    } 
 
 
 
    public class PrmaryScreenResolution 
    { 
        static public string ChangeResolution(int width, int height, int freq) 
        { 
 
            DEVMODE1 dm = GetDevMode1(); 
 
            if (0 != User_32.EnumDisplaySettings(null, User_32.ENUM_CURRENT_SETTINGS, ref dm)) 
            { 
 
                dm.dmPelsWidth = width; 
                dm.dmPelsHeight = height; 
                dm.dmDisplayFrequency = freq;
 
                int iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_TEST); 
 
                if (iRet == User_32.DISP_CHANGE_FAILED) 
                { 
                    return "Unable to process your request. Sorry for this inconvenience."; 
                } 
                else 
                { 
                    iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_UPDATEREGISTRY); 
                    switch (iRet) 
                    { 
                        case User_32.DISP_CHANGE_SUCCESSFUL: 
                            { 
                                return "YES"; 
                            } 
                        case User_32.DISP_CHANGE_RESTART: 
                            { 
                                return "NO-RESTART"; 
                            } 
                        default: 
                            { 
                                return "NO"; 
                            } 
                    } 
 
                } 
 
 
            } 
            else 
            { 
                return "NO"; 
            } 
        } 
 
        private static DEVMODE1 GetDevMode1() 
        { 
            DEVMODE1 dm = new DEVMODE1(); 
            dm.dmDeviceName = new String(new char[32]); 
            dm.dmFormName = new String(new char[32]); 
            dm.dmSize = (short)Marshal.SizeOf(dm); 
            return dm; 
        } 
    } 
} 
 
"@ 
 
Add-Type $pinvokeCode -ErrorAction SilentlyContinue 
[Resolution.PrmaryScreenResolution]::ChangeResolution($width,$height,$freq)
}

if (((Get-WmiObject win32_videocontroller).MaxRefreshRate -ge 120 | Measure-Object -Line).Lines -gt 0 -and (Test-Path -Path "S:\SDHD\FORCE_CVT" -ErrorAction SilentlyContinue) -eq $false) {
    if ((Set-ScreenResolution -Width 1920 -Height 1080 -Freq 120 -ErrorAction SilentlyContinue) -eq "YES") {
        Set-Content -Encoding utf8 -Value "haruna=false`nsp_en=found_sp" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\current_config.txt"
        #Start-Process -WindowStyle Hidden -FilePath "C:\Windows\system32\reg.exe" -ArgumentList "IMPORT `"C:\SEGA\System\settings\SDHD\serial-sp.reg`""
    } else {
        Set-ScreenResolution -Width 1920 -Height 1080 -Freq 60 -ErrorAction SilentlyContinue
        Set-Content -Encoding utf8 -Value "haruna=false`nsp_en=found_cvt" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\current_config.txt"
        #Start-Process -WindowStyle Hidden -FilePath "C:\Windows\system32\reg.exe" -ArgumentList "IMPORT `"C:\SEGA\System\settings\SDHD\serial-cvt.reg`""
    }
} else {
    Set-ScreenResolution -Width 1920 -Height 1080 -Freq 60 -ErrorAction SilentlyContinue
    Set-Content -Encoding utf8 -Value "haruna=false`nsp_en=found_cvt" -Path "C:\SEGA\system\preboot\preboot_Data\StreamingAssets\current_config.txt"
    #Start-Process -WindowStyle Hidden -FilePath "C:\Windows\system32\reg.exe" -ArgumentList "IMPORT `"C:\SEGA\System\settings\SDHD\serial-cvt.reg`""
}

#Start-Process -WindowStyle Hidden -FilePath "C:\Windows\System32\pnputil.exe" -ArgumentList '/restart-device "ACPI\PNP0501\0"'
#Start-Process -WindowStyle Hidden -FilePath "C:\Windows\System32\pnputil.exe" -ArgumentList '/restart-device "ACPI\PNP0501\1"'
#Start-Process -WindowStyle Hidden -FilePath "C:\Windows\System32\pnputil.exe" -ArgumentList '/restart-device "ACPI\PNP0501\2"'
#Start-Process -WindowStyle Hidden -FilePath "C:\Windows\System32\pnputil.exe" -ArgumentList '/restart-device "ACPI\PNP0501\3"'

# SIG # Begin signature block
# MIIGEgYJKoZIhvcNAQcCoIIGAzCCBf8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSOYRdsupY2i1rYlXcR8tNeMB
# dp6gggOCMIIDfjCCAmagAwIBAgIQJlq0EDKWmKtOwveGVRLWsTANBgkqhkiG9w0B
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
# BgkqhkiG9w0BCQQxFgQUNcP87H47BQA0xXORatkGOIemx9kwDQYJKoZIhvcNAQEB
# BQAEggEAg8S8bFV9BxOlRb18pOrajCKQrEFL8CB8L5YK3AQWwobOq11uB+Bv8lqt
# Dw41114WqZhCkG3LkUhCKBRwa0f7WA7rgDrWfIEGFcnwTyIO/dUcUtqeiIq9wqdZ
# NrQffOAl4VJe2oDSfCdVBvBTfiFLBqe5xFZFP1zvtbMbUF+W+C3655SDUCKQg4uv
# Ouj8PvM+SSzTwUBoiOQZhCKM/TCKCHrAlHpbluS3b9Na9+3lZH+OK17Q+kZJAFWf
# l3TIiNjpcjlpMxlLKaWP7Km76q6M7Y1E4CS3tBVVHiwYMbLpVRhUXf5WH4EMG0Lj
# rYLLW157KGOHXOiGuVVLUW/6jtBH7w==
# SIG # End signature block
