﻿$cert = $(Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*Missless*" })
$tech_name = ""

if (($cert | Measure-Object).Count -gt 0) {
    $date = (Get-Date).ToString("yyMMdd-HHmm")
    $password = ""

    $game_id = ""
    $game_key = ""
    $game_iv = ""

    $keychip_id = (Read-Host "Enter Keychip ID")
    if ($keychip_id[4] -ne '-') {
        $keychip_id = $keychip_id.Substring(0, 4) + '-' + $keychip_id.Substring(4)
    }

    $board_id = (Read-Host "Enter Board ID")
    $board_id_alt = $board_id
    if ($board_id[4] -eq '-') {
        $board_id.Substring(0, 4) + $board_id.Substring(5)
    }
    if ($board_id[4] -ne '-') {
        $board_id_alt = $board_id.Substring(0, 4) + '-' + $board_id.Substring(4)
    }
    if (($board_id | Measure-Object -Character).Characters -gt 10) {
        $auth_string = "${game_id} ${game_key} ${game_iv} ${keychip_id} ${board_id}"
    } else {
        $auth_string = "${game_id} ${game_key} ${game_iv} ${keychip_id}"
    }

    $user_name = (Read-Host "Enter Owner/Cab#")

    Write-Host "= KEYCHIP INFOMATION ========================"
    Write-Host "Approver   : ${tech_name}"
    Write-Host "Owner/Cab# : ${user_name}"
    Write-Host "Keychip ID : ${keychip_id}"
    Write-Host "Board ID   : ${board_id_alt}"
    Write-Host "=============================================`n"

    $line = "# GENERATED BY ${tech_name} for ${user_name} ON ${date}`n"
    $line += '$keychip_config = "${keychip_config} --auth `"'
    $line += [Convert]::ToBase64String([char[]]$auth_string)
    $line += '`""'
    $line += "`n"

    Set-Content -Encoding UTF8 -Value $line -Path ".\SYSTEM_A000_KEYCHIP_ID\settings\auth.keychip.ps1" -ErrorAction Stop | Out-Null

    Write-Host "Signing..."
    Set-AuthenticodeSignature -FilePath '.\SYSTEM_A000_KEYCHIP_ID\*\*.ps1' -Certificate $cert -ErrorAction Stop | Out-Null
    Set-AuthenticodeSignature -FilePath '.\SYSTEM_A000_KEYCHIP_ID\*.ps1' -Certificate $cert -ErrorAction Stop | Out-Null

    Remove-Item -Path ".\SYSTEM_A000_KEYCHIP_ID_${user_name}_${date}.pack" -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    & 'C:\Program Files\7-Zip-Zstandard\7z.exe' a -mhe=on -t7z -mx=22 -m0=bcj -bsp1 -m1=zstd -ssw  -p"${password}" -r ".\SYSTEM_A000_KEYCHIP_ID_${user_name}_${date}.pack" '.\SYSTEM_A000_KEYCHIP_ID\*' | Out-Null
    Write-Host "OK"
    explorer .\
} else {
    Write-Host "Missing Signing Certificate!"
}
Start-Sleep -Seconds 5