# Secret Word Society

Minimale Flutter-App: ein Bildschirm mit **Hello, world!**. Zielplattform ist Android.

## Starten

Im Projektordner in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

Das Skript verwendet die aktuellen Android Platform-Tools, startet bei Bedarf den vorhandenen Emulator `Medium_Phone_API_36.1`, wartet auf Android und startet die App gezielt auf einem Android-Geraet. Wenn ein Android-Handy verbunden ist, kann es stattdessen verwendet werden. Bei mehreren Geraeten wird das erste bereite Android-Geraet verwendet.

Im Flutter-Terminal: `r` = Hot Reload, `R` = Hot Restart, `q` = beenden, `d` = Terminal trennen und App weiterlaufen lassen.

## Android Studio

1. Diesen Projektordner oeffnen (mit `pubspec.yaml`, nicht nur `android/`).
2. Als Run-Konfiguration **main.dart** auswaehlen.
3. Als Ziel **Medium Phone API 36.1** auswaehlen, bei Bedarf vorher unter **Tools > Device Manager** starten.
4. **Run** klicken.

**Windows** ist hier kein eingerichtetes App-Ziel. Fuer Flutter **main.dart** verwenden.

Weitere Erklaerungen und die Diagnose: [ANDROID_STUDIO_SETUP.md](ANDROID_STUDIO_SETUP.md).

## Dateien und Checks

- `lib/main.dart`: die komplette HelloWorld-App.
- `test/widget_test.dart`: prueft, ob Hello World angezeigt wird.
- `android/`: von Flutter erzeugte Android-Anbindung.

```powershell
flutter analyze
flutter test
```
