# Android-Integrationstests

Die Tests in `integration_test/app_test.dart` verwenden das offizielle
Flutter-SDK-Paket `integration_test`. Sie starten den regulären App-Einstieg und
bedienen die Flutter-Oberfläche in einer laufenden Android-App. Der Wortkatalog
wird aus den tatsächlich gebündelten Assets geladen, ohne Testkatalog oder
ersetzte Plattformkanäle.

## Abgedeckte Abläufe

1. Leere Sitzung starten, Anna, Ben und Cem über die Oberfläche hinzufügen und
   eine Runde starten. Alle drei Karten einzeln aufdecken und wieder verbergen.
   Genau zwei Personen müssen dasselbe Wort und genau eine Person den dazu
   passenden Hinweis erhalten. Jede Übergabe ist verdeckt; nach der letzten
   Karte erscheint die Bereit-Ansicht.
2. Eine sichtbare Karte über „Gruppe bearbeiten“ verbergen und den
   Verlassensdialog abbrechen. Dieselbe Person kann dasselbe Geheimnis erneut
   aufdecken. Danach bei der zweiten Person die Runde tatsächlich verlassen:
   Alle drei Namen bleiben erhalten. Eine neue Runde beginnt wieder verdeckt
   bei der ersten Person und lässt sich aufdecken.

Jeder Test beginnt mit einer neuen App-Widget-Instanz und leerem Sitzungsspeicher,
auch wenn beide Tests im selben Android-Prozess laufen. Die Tests setzen keine
bestimmte zufällige Imposter-Person und kein bestimmtes Wort voraus. Stattdessen
prüfen sie die beobachtete Verteilung gegen den mitgelieferten Katalog.

## Lokal ausführen

Voraussetzungen: Flutter 3.47.7, eingerichtetes Android-SDK und ein gestarteter
Emulator oder ein per ADB erreichbares Android-Testgerät. Für den lokalen
Emulator kann der Android Studio Device Manager verwendet werden.

Im Projektordner:

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter devices
flutter test integration_test/app_test.dart -d emulator-5554 --reporter expanded
```

`emulator-5554` gegebenenfalls durch die angezeigte Android-Geräte-ID ersetzen.
Der Test installiert eine Testversion der App und ersetzt die aktuelle Sitzung.
Zum normalen Spielen danach die App über `start.ps1` oder Android Studio starten.

`flutter test --no-pub` führt weiterhin nur die schnellen Tests in `test/` aus.
Gerätetests werden gezielt über den zusätzlichen Pfad aufgerufen.

Für den Release-Build `flutter build apk --release` verwenden. Bei Release-Build
und Gerätetests bewusst kein `--no-pub` ergänzen: Flutter 3.47.7 überspringt damit
auch das Erneuern der nativen Pluginregistrierung. Nach einem Debug-/Testlauf
kann dann der Release-Build am nur für Tests verfügbaren `integration_test`-Plugin
scheitern; umgekehrt muss es vor einem Gerätetest wieder registriert werden.
Der normale Flutter-Befehl erzeugt die Registrierung passend zum Buildmodus neu.
Der vorherige Schritt `flutter pub get --enforce-lockfile` bleibt in der CI erhalten.
Hintergrund: [Flutter-Issue #169336](https://github.com/flutter/flutter/issues/169336).

## GitHub Actions

Der Workflow `.github/workflows/ci.yml` hat zwei unabhängige Jobs:

- `android`: Formatierung einschließlich `integration_test/`, Analyse,
  Unit-/Widget-Tests und Android-Release-Build.
- `android-integration`: Flutter und Java einrichten, gesperrte Abhängigkeiten
  installieren, Lokalisierungen erzeugen, KVM aktivieren und den Emulator starten.
  Android API 35, `google_apis`, `x86_64`, Pixel-7-Pro-Profil; Animationen aus,
  keine gespeicherten Emulator-Snapshots. Anschließend derselbe Testbefehl wie
  lokal. Die Emulator-Action ist wie die übrigen Actions auf eine Commit-ID fixiert.

Beide Jobs laufen bei Pull Requests gegen `main`, Pushes auf `main` und manuellen
Workflowstarts. Fehler schlagen sich im jeweiligen Job und Gesamtstatus nieder.
Logs enthalten Testnamen, Fehler und Laufzeiten. Es gibt keinen Artefaktupload.
Der Emulatorjob hat 30 Minuten Gesamttimeout und 180 Sekunden Boot-Timeout;
das Warten auf eine ruhige Flutter-Oberfläche ist pro Aktion auf 15 Sekunden
begrenzt. Die tatsächliche CI-Laufzeit muss am ersten GitHub-Lauf gemessen werden.

## Grenzen und spätere Ergänzungen

- Diese Tests ergänzen die schnelleren Unit-/Widget-Tests; Varianten der Regeln,
  Fehlerfälle und kleine Displays werden weiterhin dort geprüft.
- Texteingabe erfolgt über Flutter-Test-APIs. Das ist kein Test einer bestimmten
  Android-Tastatur. Dialoge werden über App-Buttons bedient; Android-System-Zurück
  und echte App-Unterbrechungen sind in dieser Suite noch nicht automatisiert.
- `integration_test` bedient keine nativen Systemoberflächen. Für echte
  App-Wechsel, Systemdialoge und weitere Geräteaktionen ist Patrol eine mögliche
  spätere Ergänzung.
- `FLAG_SECURE`, Android-Screenshots und App-Vorschauen werden hier nicht
  überprüft. Der bestehende Fenster-Schutz bleibt aktiv; die Tests benötigen
  keine Bildschirmaufnahmen.
- Layout, Animationen, echter Screenreader und herstellerspezifisches Verhalten
  brauchen weiterhin gezielte Sicht-/Geräteprüfungen. Ein Emulator ersetzt keine
  Prüfung auf einem physischen Android-Gerät.
- Timer, Abstimmung, Ergebnis und Folgerunde werden nach ihrer UI-Implementierung
  als vollständiger Spielablauf ergänzt. iOS ist hier noch kein Testziel.

## Lokale Erstprüfung am 23.10.2026

- Flutter 3.47.7 auf Windows, Emulator `Medium_Phone_API_36.1` (`emulator-5554`).
  Beide Integrationstests bestanden: etwa 23 Sekunden Testausführung zusätzlich
  zu etwa 125 Sekunden erstem Debug-Build und 3 Sekunden Installation. Das ist
  eine einzelne lokale Messung und keine Vorhersage für GitHub Actions.
- Alle 34 bestehenden Unit-/Widget-Tests bestanden; Flutter-Analyse ohne Befund.
  Formatprüfung und `git diff --check` erfolgreich.
- Android-Release-APK mit dem endgültigen Buildbefehl erfolgreich gebaut.
  Die generierte Release-Pluginregistrierung enthält das Test-Plugin nicht.
  Der anfängliche Fehler mit `--no-pub` ist durch die oben beschriebene
  Befehlsanpassung behoben. Anschließend bestanden beide Gerätetests auch mit
  dem endgültigen Befehl erneut (34 Sekunden Debug-Build, 23 Sekunden Tests).
- Workflow mit `actionlint` 1.7.12 ohne Befund geprüft. Der neue GitHub-Job ist
  lokal vorbereitet; sein erster echter Lauf auf Ubuntu mit Android API 35 steht
  nach dem Push noch aus.

Grundlagen: [Flutter-Integrationstests](https://docs.flutter.dev/testing/integration-tests),
[Flutter-Testarten und native Grenzen](https://docs.flutter.dev/testing/overview),
[Android Emulator Runner](https://github.com/ReactiveCircus/android-emulator-runner).
