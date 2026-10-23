$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot

try {
    $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
    $adb = Join-Path $sdk 'platform-tools\adb.exe'
    if (-not (Test-Path -LiteralPath $adb)) {
        throw "Android SDK nicht gefunden: $sdk"
    }

    # Fuer diesen Start die aktuellen Platform-Tools verwenden.
    $originalPath = $env:Path
    $env:Path = "$(Join-Path $sdk 'platform-tools');$env:Path"

    function Get-AndroidDevice {
        & $adb devices | ForEach-Object {
            if ($_ -match '^(\S+)\s+device\s*$') { $Matches[1] }
        } | Select-Object -First 1
    }

    $device = Get-AndroidDevice
    $emulatorBooting = & $adb devices | Select-String '^emulator-\d+\s+offline\s*$'
    if (-not $device -and -not $emulatorBooting) {
        Write-Host 'Starte Android-Emulator ...'
        flutter emulators --launch Medium_Phone_API_36.1
        if ($LASTEXITCODE -ne 0) { throw 'Emulator konnte nicht gestartet werden.' }
    }

    $deadline = (Get-Date).AddMinutes(2)
    do {
        $device = Get-AndroidDevice
        if ($device) {
            $booted = & $adb -s $device shell getprop sys.boot_completed 2>$null
            if ("$booted".Trim() -eq '1') { break }
        }
        if ((Get-Date) -ge $deadline) { throw 'Android ist nach 2 Minuten nicht startbereit. Device Manager pruefen.' }
        Start-Sleep -Seconds 2
    } while ($true)

    Write-Host "Starte Secret Word Society auf $device ..."
    flutter run -d $device
    if ($LASTEXITCODE -ne 0) { throw 'Flutter konnte die App nicht starten. Siehe Fehlermeldung oben.' }
}
finally {
    if ($null -ne $originalPath) { $env:Path = $originalPath }
    Pop-Location
}
