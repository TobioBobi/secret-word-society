# Secret Word Society

Flutter-App für ein Offline-Partyspiel auf Android. Ihr könnt eure Gruppe anlegen,
Namen hinzufügen/entfernen und ab drei Personen eine Runde starten. Jede Person
deckt ihre private Karte bewusst auf und verbirgt sie vor der nächsten Übergabe.
Nach der letzten Person erscheint die Bereit-Ansicht; Timer und Abstimmung folgen
in Tickets 5–6.
Der Spielkern und 16 deutsche Wort-Hinweis-Paare sind bereits enthalten.

## MVP-Entwurf

Ticket 1 dokumentiert [Ablauf, Regeln und Gestaltung](docs/mvp/ticket-1-ablauf-design.md).
Der [klickbare Entwurf](docs/mvp/prototype.html) lässt sich lokal im Browser öffnen.
Er zeigt eine Beispielrunde. [Ticket 2: Spielkern und Wortbestand](docs/mvp/ticket-2-spielkern.md)
beschreibt die implementierte Logik und die Anbindung für die folgenden Tickets.
[Ticket 3: Spieleranlage und Rundenstart](docs/mvp/ticket-3-spieleranlage.md)
beschreibt die Spieleranlage.
[Ticket 4: Geheime Karten](docs/mvp/ticket-4-geheime-karten.md) beschreibt
die Verteilung, sichere Rücknavigation und den Android-Geheimnisschutz.

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

- `lib/main.dart`: App-Einstieg, Party-Theme und deutsche Lokalisierung.
- `lib/ui/`: Spieleranlage, Kartenverteilung, Bereit-Ansicht und Gestaltung.
- `lib/game/game_session.dart`: Gruppe und aktuelle Runde im Sitzungsspeicher.
- `lib/game/`: Flutter-unabhängige Modelle und Phasenwechsel einer Runde.
- `assets/words/de.json`: eigener deutscher Startwortbestand, offline gebündelt.
- `lib/data/word_catalog_loader.dart`: Laden und Prüfen der gebündelten Inhalte.
- `lib/l10n/app_de.arb`: deutsche UI-Texte; Dart-Lokalisierungen werden generiert.
- `test/`: Spielregeln, Inhalte, Sitzungsverwaltung und Bedienung der Ansichten.
- `android/`: Android-Anbindung mit geschütztem App-Fenster (`FLAG_SECURE`).

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

Weitere Sprachen kommen später als eigene ARB-Dateien und Wortkataloge hinzu.
Aktuell ist ausschließlich Deutsch verfügbar. Generierte `app_localizations*.dart`
nicht von Hand bearbeiten; `flutter gen-l10n` erzeugt sie aus den ARB-Dateien neu.

## Continuous Integration

Der GitHub-Actions-Workflow [Flutter CI](.github/workflows/ci.yml) prüft Pull Requests
gegen `main` und jeden Push auf `main`. Nach Übernahme des Workflows in `main`
lässt er sich unter **Actions > Flutter CI > Run workflow** auch manuell starten.

Er verwendet Flutter **3.47.7**, Java **17** und Ubuntu **24.04**. Abhängigkeiten
werden anhand der eingecheckten `pubspec.lock` installiert. Danach folgen
Lokalisierungsgenerierung, Formatprüfung, statische Analyse, alle Unit-/Widget-Tests
und ein Android-Release-Build. Ein fehlgeschlagener Schritt stoppt den Job.

Ergebnisse und Logs stehen am Pull Request und unter **Actions**. Der Release-Build
nutzt derzeit die Debug-Signierung aus der Android-Konfiguration; für eine
Store-Veröffentlichung ist später eine eigene Release-Signierung nötig.
Der Workflow führt keine Emulator- oder Gerätetests aus.

Dieselben Prüfungen lokal (Flutter 3.47.7):

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub --fatal-infos
flutter test --no-pub
flutter build apk --release --no-pub
```

Bei Flutter-Upgrades die feste Version im Workflow und diese Anleitung gemeinsam
aktualisieren. Der Workflow meldet seinen Status am Pull Request; eine verpflichtende
Merge-Sperre muss separat über GitHub-Branch-Regeln eingerichtet werden.
