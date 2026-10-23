# Entwicklung mit Flutter und Android

## Starten

Im Projektordner:

```powershell
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

Das Skript startet bei Bedarf den vorhandenen Android-Emulator und waehlt gezielt ein Android-Geraet. Weitere Bedienhinweise stehen in [README.md](README.md).

In Android Studio den Projektordner mit `pubspec.yaml` oeffnen, **main.dart** als Run-Konfiguration und **Medium Phone API 36.1** als Ziel waehlen. Bei Bedarf den Emulator unter **Tools > Device Manager** starten.

## Eingerichtete Werkzeuge

Stand: 23.10.2026.

- Flutter stable 3.47.7 mit Dart 3.13.5: `C:\Users\tobia\development\flutter`
- Android Studio mit Flutter- und Dart-Plugin.
- Android SDK: `C:\Users\tobia\AppData\Local\Android\Sdk`
- Command-line Tools, Plattformen, Build-Tools und benoetigtes NDK sind vorhanden; Android-Lizenzen sind akzeptiert.
- Emulator: `Medium_Phone_API_36.1`, Hardwarebeschleunigung verfuegbar.

`start.ps1` verwendet fuer seinen Prozess die aktuellen Android Platform-Tools. Globale Einstellungen werden nicht geaendert.

## Projektstruktur

- `lib/main.dart`: die komplette HelloWorld-App in Dart.
- `test/widget_test.dart`: prueft die Anzeige von Hello World.
- `android/`: benoetigte Android-Anbindung aus der Flutter-Vorlage. Dazu gehoeren auch `MainActivity.kt` und die Gradle-Dateien; diese sind Bestandteil der Flutter-App.

Das Projekt ist fuer Android eingerichtet. Windows als Entwicklungsrechner bedeutet nicht, dass die App als Windows-Desktop-App gestartet wird. Die Visual-Studio-Warnung in `flutter doctor` betrifft Windows-Desktop-Builds und erfordert fuer diese Android-App keine Nachinstallation.

## Pruefen und entwickeln

```powershell
flutter doctor -v
flutter analyze
flutter test
```

APK-Build, Start im Emulator, HelloWorld-Anzeige und Hot Reload wurden erfolgreich geprueft. Nach einer Aenderung an `lib/main.dart` im laufenden Flutter-Terminal `r` druecken. Der erste Android-Build kann durch Downloads und Kompilierung mehrere Minuten dauern; fuer normale Aenderungen ist kein `flutter clean` erforderlich.

Offizielle Anleitungen:

- [Flutter installieren und erste App ausprobieren](https://docs.flutter.dev/install/quick)
- [Android-Entwicklung mit Flutter einrichten](https://docs.flutter.dev/platform-integration/android/setup)
