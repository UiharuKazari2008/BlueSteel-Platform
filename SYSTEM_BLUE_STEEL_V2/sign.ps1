cd 'H:\Blue Steel OS v2\'

Write-Host "Compile sgx boot..."
Set-AuthenticodeSignature -FilePath '.\boot.ps1' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })
Set-AuthenticodeSignature -FilePath '.\sgxinithandle.ps1' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })
Invoke-PS2EXE '.\boot.ps1' ".\SYSTEM_BLUE_STEEL_ALLS_SDHD_SW_KEY\sgxsegaboot.exe"
Invoke-PS2EXE '.\sgxinithandle.ps1' ".\SYSTEM_BLUE_STEEL_ALLS_SDHD_SW_KEY\sgxinithandle.exe"
Copy-Item -Path ".\SYSTEM_BLUE_STEEL_ALLS_SDHD_SW_KEY\sgxsegaboot.exe" -Destination ".\SYSTEM_BLUE_STEEL_NU_LEGACY_SDHD_SW_KEY\sgxsegaboot.exe"
Copy-Item -Path ".\SYSTEM_BLUE_STEEL_ALLS_SDHD_SW_KEY\sgxinithandle.exe" -Destination ".\SYSTEM_BLUE_STEEL_NU_LEGACY_SDHD_SW_KEY\sgxinithandle.exe"

Write-Host "Signing..."
Set-AuthenticodeSignature -FilePath '.\*\*\*.ps1' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })
Set-AuthenticodeSignature -FilePath '.\*\*\*.exe' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })
Set-AuthenticodeSignature -FilePath '.\*\*\preboot_Data\StreamingAssets\*.ps1' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })
Set-AuthenticodeSignature -FilePath '.\*\*\preboot.exe' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })

Set-AuthenticodeSignature -FilePath '.\*\*.ps1' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })
Set-AuthenticodeSignature -FilePath '.\*\*.exe' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })

Set-AuthenticodeSignature -FilePath '..\Game Installers\*\*.*\*.ps1' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })
Set-AuthenticodeSignature -FilePath '..\Game Installers\*\*.*\bin\*.exe' -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })

