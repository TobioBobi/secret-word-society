# Secret Word Society

Flutter-App für ein Offline-Partyspiel auf Android. Ihr könnt eure Gruppe anlegen,
Namen hinzufügen/entfernen und ab drei Personen eine Runde starten. Jede Person
deckt ihre private Karte bewusst auf und verbirgt sie vor der nächsten Übergabe.
Nach der letzten Person startet ihr bewusst den Zwei-Minuten-Countdown. Die Zeit
läuft auch bei App-Wechsel oder gesperrtem Bildschirm weiter; bei Ablauf erscheint
die mündliche Abstimmung mit Namensauswahl. Nach Bestätigung seht ihr den
tatsächlichen Imposter, das Wort und den Gewinner. „Noch eine Runde“ beginnt
wieder verdeckt mit derselben Gruppe und neu ausgelosten Geheimnissen.
Die App enthält 100 eigene deutsche Wort-Hinweis-Paare mit Hinweisen aus ein bis
zwei Wörtern. In einer Sitzung wird jedes Wort einmal zufällig gezogen,
bevor der Vorrat erneut beginnt; auch am
Übergang wiederholt sich kein Wort direkt. Die Wortfolge bleibt beim Bearbeiten
der Gruppe erhalten und wird bei einem App-Neustart zurückgesetzt.

## MVP-Entwurf

Ticket 1 dokumentiert [Ablauf, Regeln und Gestaltung](docs/mvp/ticket-1-ablauf-design.md).
Der [klickbare Entwurf](docs/mvp/prototype.html) lässt sich lokal im Browser öffnen.
Er zeigt eine Beispielrunde. [Ticket 2: Spielkern und Wortbestand](docs/mvp/ticket-2-spielkern.md)
beschreibt die implementierte Logik und die Anbindung für die folgenden Tickets.
[Ticket 3: Spieleranlage und Rundenstart](docs/mvp/ticket-3-spieleranlage.md)
beschreibt die Spieleranlage.
[Ticket 4: Geheime Karten](docs/mvp/ticket-4-geheime-karten.md) beschreibt
die Verteilung, sichere Rücknavigation und den Android-Geheimnisschutz.
[Ticket 5: Zwei-Minuten-Spielphase](docs/mvp/ticket-5-spielphase.md) beschreibt
Countdown, Unterbrechungen und den Übergang zur Abstimmung.
[Ticket 6: Abstimmung, Auflösung und neue Runde](docs/mvp/ticket-6-abstimmung.md)
schließt den vollständigen Spielablauf ab.
[Ticket 7: Deutsche Inhalte und Probespiel](docs/mvp/ticket-7-inhalte.md)
beschreibt den erweiterten Katalog, die Wortfolge und die Prüfliste für echte Runden.
[Ticket 8: Party-Look und Android-Abnahme](docs/mvp/ticket-8-android-mvp.md)
beschreibt den visuellen Feinschliff und die abschließende MVP-Prüfung.
[Ticket 20: Kurze Hinweise](docs/mvp/ticket-20-kurze-hinweise.md)
beschreibt die Überarbeitung auf ein bis zwei Wörter und den Katalogtest.

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
- `lib/ui/`: Spieleranlage, Kartenverteilung, Countdown, Abstimmung und Ergebnis.
- `lib/game/game_session.dart`: Gruppe und aktuelle Runde im Sitzungsspeicher.
- `lib/game/`: Flutter-unabhängige Modelle und Phasenwechsel einer Runde.
- `lib/game/word_deck.dart`: Wortvorrat ohne Wiederholung innerhalb einer Sitzung.
- `assets/words/de.json`: eigener deutscher Startwortbestand, offline gebündelt.
- `lib/data/word_catalog_loader.dart`: Laden und Prüfen der gebündelten Inhalte.
- `lib/l10n/app_de.arb`: deutsche UI-Texte; Dart-Lokalisierungen werden generiert.
- `test/`: Spielregeln, Inhalte, Sitzungsverwaltung und Bedienung der Ansichten.
- `integration_test/`: Bedienabläufe in der laufenden Android-App mit echten Assets.
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
Ein separater Job startet einen Android-Emulator mit API 35 (`google_apis`,
`x86_64`, Pixel-7-Pro-Profil) und führt die drei Integrationstests aus. Er läuft
parallel zu Analyse, Unit-/Widget-Tests und Release-Build. Auch ein fehlgeschlagener
Integrationstest meldet den Workflow als fehlgeschlagen. Es werden keine APKs
oder Bildschirmaufnahmen hochgeladen.

Dieselben Prüfungen lokal (Flutter 3.47.7):

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --no-pub --fatal-infos
flutter test --no-pub
flutter build apk --release
```

Integrationstests zusätzlich auf einem gestarteten Android-Emulator oder einem
verbundenen Testgerät ausführen (`flutter devices` zeigt die Geräte-ID):

```powershell
flutter devices
flutter test integration_test/app_test.dart -d emulator-5554 --reporter expanded
```

Dabei wird eine Testversion installiert; eine laufende Spielsitzung auf dem
gewählten Gerät geht verloren. Abdeckung, Voraussetzungen und Grenzen:
[Android-Integrationstests](docs/testing.md).

Bei Flutter-Upgrades die feste Version im Workflow und diese Anleitung gemeinsam
aktualisieren. Der Workflow meldet seinen Status am Pull Request; eine verpflichtende
Merge-Sperre muss separat über GitHub-Branch-Regeln eingerichtet werden.
