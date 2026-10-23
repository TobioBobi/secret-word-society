# Secret Word Society

Flutter-App für ein Offline-Partyspiel auf Android. Ticket 2 enthält den getesteten
Spielkern und 16 deutsche Wort-Hinweis-Paare. Die Oberfläche zeigt vorerst
**Hallo, Welt!**; die bedienbaren Spielansichten folgen ab Ticket 3.

## MVP-Entwurf

Ticket 1 dokumentiert [Ablauf, Regeln und Gestaltung](docs/mvp/ticket-1-ablauf-design.md).
Der [klickbare Entwurf](docs/mvp/prototype.html) lässt sich lokal im Browser öffnen.
Er zeigt eine Beispielrunde. [Ticket 2: Spielkern und Wortbestand](docs/mvp/ticket-2-spielkern.md)
beschreibt die implementierte Logik und die Anbindung für die folgenden Tickets.

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

- `lib/main.dart`: vorläufiger Startbildschirm mit deutscher Lokalisierung.
- `lib/game/`: Flutter-unabhängige Modelle und Phasenwechsel einer Runde.
- `assets/words/de.json`: eigener deutscher Startwortbestand, offline gebündelt.
- `lib/data/word_catalog_loader.dart`: Laden und Prüfen der gebündelten Inhalte.
- `lib/l10n/app_de.arb`: deutsche UI-Texte; Dart-Lokalisierungen werden generiert.
- `test/`: Spielregeln, Phasenwechsel, Inhalte, Asset-Laden und Startbildschirm.
- `android/`: von Flutter erzeugte Android-Anbindung.

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

Weitere Sprachen kommen später als eigene ARB-Dateien und Wortkataloge hinzu.
Aktuell ist ausschließlich Deutsch verfügbar. Generierte `app_localizations*.dart`
nicht von Hand bearbeiten; `flutter gen-l10n` erzeugt sie aus den ARB-Dateien neu.
