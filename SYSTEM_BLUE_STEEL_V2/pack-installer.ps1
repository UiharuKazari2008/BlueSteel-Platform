$password = ""
$date = (Get-Date).ToString("yyMMdd-HHmm")


Write-Host "Generating System Installer Package (ALLS Series)..."
Remove-Item -Path "H:\Built Packages\SYSTEM_BLUE_STEEL_INS_ALLS_SDHD_SW_${date}.pack" -Force -Confirm:$false -ErrorAction SilentlyContinue
& 'C:\Program Files\7-Zip-Zstandard\7z.exe' a -mhe=on -t7z -mmt4 -mx=22 -m0=bcj -bsp1 -m1=zstd -ssw  -p"${password}" -r "H:\Built Packages\SYSTEM_BLUE_STEEL_INS_ALLS_SDHD_SW_${date}.pack" 'H:\Blue Steel OS v2\SYSTEM_BLUE_STEEL_ALLS_SDHD_SW_KEY\*'

Write-Host "Generating System Installer Package (Nu Series)..."
Remove-Item -Path "H:\Built Packages\SYSTEM_BLUE_STEEL_INS_NU_LEGACY_SDHD_SW_${date}.pack" -Force -Confirm:$false -ErrorAction SilentlyContinue
& 'C:\Program Files\7-Zip-Zstandard\7z.exe' a -mhe=on -t7z -mmt4 -mx=22 -m0=bcj -bsp1 -m1=zstd -ssw  -p"${password}" -r "H:\Built Packages\SYSTEM_BLUE_STEEL_INS_NU_LEGACY_SDHD_SW_${date}.pack" 'H:\Blue Steel OS v2\SYSTEM_BLUE_STEEL_NU_LEGACY_SDHD_SW_KEY\*'

