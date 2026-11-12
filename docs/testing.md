# Android-Integrationstests

## Textbezogene Übergabe (Issue #82)

Die Weitergabe verlangt seit #82 ungefähr halb sichtbaren Wort-/Hinweistext.
Die bisherige 95-Prozent-Schwelle bleibt für private Semantik und Positionierung
erhalten. `test/text_handoff_test.dart` prüft die neue Freigabe an der gerenderten
Kurvenmaske, einschließlich mehrzeiliger Texte, großer Schrift auf kleinem Display,
beider Rollen, letzter Person, Zurückziehen und Unterbrechungen. Die bestehenden
Vorhangtests prüfen zusätzlich Tastatur-/Semantikaktionen und den visuellen Hinweis.
Ältere Berichte über vollständiges Ansehen beschreiben die frühere Schwelle.

## Aufnahmefreigabe (Issue #62)

Android-Screenshots, Bildschirmaufnahmen und Bildschirmübertragung sind in allen
Ansichten erlaubt, einschließlich aufgedeckter Wörter und Imposter-Karten.
Die Activity setzt kein `FLAG_SECURE`; auch App-Vorschauen haben keinen gesonderten
Schutz. Es gibt dafür keine Einstellung, Warnung oder Bestätigung.
Der Übergabevorhang und das Verdecken bei Unterbrechungen bleiben unverändert.

Native Abnahme: normale Ansicht und beide Kartenrollen aufnehmen; bei geöffneter
Karte Home/App-Rückkehr und Sperren/Entsperren auslösen. Danach muss dieselbe
Person mit verdecktem Geheimnis bleiben, bis sie erneut bewusst aufdeckt.
Vollständiges Ansehen und normales Loslassen müssen weiterhin genau einmal
übergeben. Geräteaufnahmen prüfen die native Freigabe; Flutter-Widgetbilder
allein weisen sie nicht nach. Frühere Prüfberichte mit aktivem Fensterschutz
weiter unten beschreiben den damaligen Stand vor #62.

Am 05.11.2026 bestanden alle 139 Unit-/Widget-Tests, die Flutter-Analyse und
die gezielte native Abnahme auf Android API 36.1. Android-Screenshots zeigen
Wort und Imposter-Hinweis; kurze native Bildschirmaufnahmen wurden erstellt.
Home/App-Rückkehr und Sperren/Entsperren verdecken die geöffnete Karte, behalten
die aktuelle Person und erlauben erneutes bewusstes Ansehen. Alle drei Karten
werden anschließend regulär übergeben. Die getrennten Reviews gegen Standards
und Issue-Spezifikation ergaben keine Befunde. Eine Übertragung an einen echten
Empfänger und Tests auf einem physischen Handy sind damit nicht nachgewiesen.

## Parallele Spieltests in der CI (Issue #64)

Die vollständige Suite `integration_test/app_test.dart` läuft auf genau zwei
unabhängigen API-35-Emulatoren. `GAME_TEST_GROUP=1` beziehungsweise `2` wird
per `--dart-define` gesetzt; ohne Argument laufen lokal weiterhin alle Tests.
Testkörper, Assertions, Produktionsuhr und echte Timerwartezeiten bleiben erhalten.
Jeder Ablauf startet weiterhin eine neue App mit leerem Sitzungsspeicher;
zusätzlich werden die Gestenhilfen vor jedem Test zurückgesetzt.

Die Zuordnung in `integration_test/support/game_test_selection.dart` basiert auf
den Einzelzeiten des erfolgreichen Vergleichslaufs
[42020929635](https://github.com/TobioBobi/secret-word-society/actions/runs/42020929635).
Die dortige Übergabeprüfung wurde seither durch die sichere Übergabe aus #47
ersetzt; ihre bisherige Zeit ist deshalb zunächst ein Näherungswert.

| Gruppe | Spielabläufe | Bisherige reine Testzeit |
| --- | --- | --- |
| 1 | Timer überspringen, manueller Timer, Gruppensieg, Verlassen/Neustart, 14 Personen | bisher ca. 4:53 ohne Überspringen-Test |
| 2 | beide manuellen Imposter-Varianten, Imposter-Sieg, unvollständig angesehene Karten, 6 Personen | ca. 4:43 |

Nach Gruppe 2 läuft weiterhin die native Fotopipeline. Die vollständige
AOT-/R8-Release-Fotoprobe läuft seit #65 unabhängig in einem eigenen
API-35-Emulatorjob parallel zu beiden Spieltestgruppen. Ihr Release-Build
startet vor dem Emulator; Installation und Offline-Ausführung mit deaktiviertem
WLAN/Mobilfunk sowie alle bisherigen Assertions bleiben erhalten. Der neue Job
hat kein `needs` auf Spieltests und verwendet keine Artefakte anderer Jobs.
Er funktioniert ebenso mit einer ungeteilten Spieltestsuite. Der normale
App-Release-Build, Analyse, Format und Unit-/Widget-Tests bleiben im Standardjob.
Alle drei Emulatorjobs verwenden dieselbe lokale Setup-Action für
Caches, KVM, Speicherbereinigung, Speicherdiagnose,
8-GiB-AVD und die verbindliche 24-GiB-Mindestprüfung.

Neue oder umbenannte Spieltests müssen einer der beiden Gruppen zugeordnet
werden. Die Registrierung verwirft unbekannte, doppelte oder ungültig zugeordnete
Tests; ein fehlender deklarierter Test oder eine leere Gruppe lässt sie ebenfalls
scheitern. Alle Spieltests verwenden den lokalen `testWidgets`-Wrapper, damit
kein Namensfilter neue Tests stillschweigend auslassen kann. Beim Ändern der
Suite immer auch beide CI-Gruppen ausführen und die Laufzeitverteilung prüfen.

Der unveränderte Pflichtcheck **Android integration tests (API 35)** ist jetzt
eine Gesamtprüfung mit `needs` auf der vollständigen Zweiermatrix und der
Release-Fotoprobe sowie `always()`. Beide Ergebnisse müssen `success` sein.
Fehler, Abbruch, übersprungene
Jobs und fehlende Ergebnisse werden abgewiesen. `fail-fast: false` lässt die
zweite Gruppe auch nach einem Fehler weiterlaufen. Der ebenfalls verpflichtende
Check **Analyze, test and build Android** bleibt unverändert; die bestehende
strikte Repository-Regel und ihre Bindung an GitHub Actions bleiben erhalten.
Ein erfolgreicher Teiljob allein erlaubt keinen Merge.

Das öffentliche Repository verwendet ausschließlich `ubuntu-24.04` als
GitHub-gehosteten Standardrunner. Deren Nutzung ist nach den am 05.11.2026
geprüften [GitHub-Konditionen](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job)
kostenlos; die zusätzliche Parallelität erhöht die Runner-Minuten.
Laufzeitmessungen und Cache-/Fehlerbeobachtungen stehen in
[Spieltest-Messungen](ci-game-test-measurements.md) und
[Messungen der parallelen Fotoprobe](ci-photo-release-measurements.md).

```sh
flutter test integration_test/app_test.dart -d emulator-5554 --reporter expanded --dart-define=GAME_TEST_GROUP=1
flutter test integration_test/app_test.dart -d emulator-5554 --reporter expanded --dart-define=GAME_TEST_GROUP=2
flutter test test/game_test_selection_test.dart
bash scripts/test-require-android-test-groups.sh
```

## Grundlage

Die Tests in `integration_test/app_test.dart` verwenden das offizielle
Flutter-SDK-Paket `integration_test`. Sie starten den regulären App-Einstieg und
bedienen die Flutter-Oberfläche in einer laufenden Android-App. Der Wortkatalog
wird aus den tatsächlich gebündelten Assets geladen, ohne Testkatalog oder
ersetzte Plattformkanäle.

Seit Issue #78 beträgt die Rundendauer 15 Sekunden pro Person bei 3–14
Personen. Drei Personen spielen 00:45, vier 01:00, vierzehn 03:30 Minuten.
Der temporäre Zehn-Sekunden-Timer ist entfernt (damit ist auch Issue #22
inhaltlich umgesetzt). Rollenstaffelung, Mehrfachabstimmung und unterschiedliche
Offline-Hinweise stehen in der [Beschreibung von Issue #25](mvp/issue-25-dynamische-runden.md).

Seit Issue #78 kann die Dauer vor dem Start in 15-Sekunden-Schritten zwischen
00:30 und 15:00 manuell gewählt werden. Seit Issue #72 erfolgt dies ausschließlich
nach der Kartenverteilung direkt vor dem Timerstart. Die Gruppenansicht enthält
keine Daueranzeige oder Zeitauswahl. Die Auswahl bleibt für Folgerunden in
der Sitzung erhalten. Ein zusätzlicher Android-Ablauf prüft die manuelle Wahl,
echten 30-Sekunden-Ablauf und die erneute Anpassung in der Folgerunde. Details:
[Rundendauer anpassen](mvp/issue-30-rundendauer.md).

Seit Issue #28 erscheint beim Timerende die dauerhafte Karte „Zeit ist um!“
mit einer einmaligen, bei reduzierten Animationen deaktivierten Bewegung.
Der Bildschirm bleibt während des sichtbaren Rundentimers automatisch wach.
Der native Android-Doppelton begleitet den Ablauf in der geöffneten App, ohne
zusätzliche Freigaben oder Einrichtung. Bei Ablauf im Hintergrund oder bei
manueller Sperre wird nach Rückkehr kein Ton nachgeholt.
Die Ablauftests prüfen den sichtbaren Übergang und verdeckte Geheimnisse.
Native Audio-/Unterbrechungsprüfungen und Grenzen stehen in der
[Beschreibung des Timersignals](mvp/issue-28-timersignal.md).

## Abgedeckte Abläufe

Seit Issue #46 führen die sichtbare Aktion „Timer überspringen“ und Zurück
während der Diskussion in denselben Bestätigungsdialog. Der Timer läuft dort
weiter; bei Ablauf verschwindet der Dialog automatisch. Bestätigtes Überspringen
beendet auch das native Timersignal und öffnet die reguläre Abstimmung.
Widget-Tests prüfen Restzeit, Unterbrechungen, veraltete Bestätigungen,
Semantik und 320 Pixel bei 200 Prozent Schrift. Ein Android-Ablauf in Gruppe 1
prüft Bestätigung, Abbruch, Ablauf im Dialog und anschließende normale Auflösung;
für diesen zusätzlichen Ablauf wird die Uhr gezielt gesteuert. Die bestehenden
Tests mit echten Timerwartezeiten bleiben erhalten.

Seit Issue #47 erfolgt die normale Übergabe nach vollständigem Ansehen,
Loslassen und vollständigem Schließen automatisch. Ungesehene Karten können
nicht übersprungen werden. Die Gerätetests verwenden dafür `_passCard` mit einer
echten Ziehgeste und Loslassen; die früher getrennte Weiter-Aktion entfällt.
Zeitgesteuerte Semantik-/Tastaturanzeige, bewusste barrierefreie Übergabe und
Unterbrechungen sind zusätzlich mit Widget-Tests abgesichert. Details:
[Sichere Übergabe](mvp/issue-47-sichere-uebergabe.md).

Seit Ticket 23 werden Geheimnisse mit einer gehaltenen Ziehgeste am unteren
Kartengriff angesehen. Widget-Tests prüfen zusätzlich
Gestenabbruch, Unterbrechungen während vollständiger und teilweiser Gesten,
mehrfaches Ansehen und die automatisch schließende Screenreader-Alternative.
Details: [Vorhang-Bedienung](mvp/ticket-23-vorhang.md).

Seit Issue #32 bewegen sich Spielerüberschrift und Avatar-Platzhalter gemeinsam
mit einer großflächigen Abdeckung. Das Geheimnis liegt fest unten. Zusätzliche
Widget-Prüfungen kombinieren Systemleisten, lange Inhalte, 200 Prozent Schrift
und reduzierte Bewegung. Die Spielerüberschrift bleibt während der Geste stabil.
Details: [Weiche Vorhangkante](mvp/issue-32-weiche-vorhangkante.md).

1. Je ein vollständiger Ablauf für Gruppen- und Imposter-Sieg: Leere Sitzung
   starten, Anna, Ben und Cem über die Oberfläche hinzufügen und
   eine Runde starten. Alle drei Karten einzeln aufdecken und wieder verbergen.
   Genau zwei Personen müssen dasselbe Wort und genau eine Person einen der drei
   dazu passenden Hinweise erhalten. Jede Übergabe ist verdeckt; nach der letzten
   Karte erscheint die Bereit-Ansicht. Anschließend die echten 45 Sekunden
   starten und bis zur Abstimmungsansicht warten. Wort und Hinweis bleiben
   dabei verborgen. Ohne Auswahl ist die Bestätigung deaktiviert. Danach den
   tatsächlichen Imposter bzw. gezielt eine andere Person auswählen und
   bestätigen; Gewinner, Verdacht, tatsächlichen Imposter und Wort prüfen.
   „Noch eine Runde“ beginnt bei Person 1 mit verdeckter Karte; alle Karten
   erneut verteilen und einen frischen Countdown bei 00:45 starten. Seit
   Ticket 7 muss die Folgerunde ein anderes Wort mit zugehörigem Hinweis haben.
   Beide Tests brauchen durch die aktuelle Spielzeit jeweils gut 45 Sekunden
   für die Diskussion; die Produktionsuhr wird nicht ersetzt.
2. Eine sichtbare Karte über Android-Zurück verbergen und den
   Verlassensdialog abbrechen. Dieselbe Person kann dasselbe Geheimnis erneut
   aufdecken. Danach bei der zweiten Person die Runde tatsächlich verlassen:
   Alle drei Namen bleiben erhalten. Eine neue Runde beginnt wieder verdeckt
   bei der ersten Person. Seit Ticket 7 werden auch hier alle Karten verteilt
   und ein anderes Wort als in der abgebrochenen Runde geprüft. Dabei lädt die
   App den Katalog erneut; die Sitzung muss ihren Wortvorrat dennoch behalten.

Jeder Test beginnt mit einer neuen App-Widget-Instanz und leerem Sitzungsspeicher,
auch wenn die Tests im selben Android-Prozess laufen. Die Tests setzen keine
bestimmte zufällige Imposter-Person und kein bestimmtes Wort voraus. Stattdessen
prüfen sie die beobachtete Verteilung gegen den mitgelieferten Katalog.
Die Test-Bindung verwendet `fullyLive`, damit auch zwischen Testaktionen die
automatisch angeforderten Countdown-Frames gezeichnet werden. Die beiden
vollständigen Abläufe prüfen zusätzlich nach zwei Sekunden, dass die sichtbare
Zeit abgenommen hat.

Seit Issue #48 lesen die Tests die tatsächlich angezeigte Person jeder
Übergabe, statt die Eingabereihenfolge vorauszusetzen. Die Aufdeckreihenfolge
wird pro Runde einmal zufällig gewählt; die vorherige Startperson ist auch
nach Abbruch und Gruppenbearbeitung an erster Position ausgeschlossen.
Spielkern-Tests prüfen alle zulässigen Reihenfolgen einer Dreiergruppe mit
gleich wahrscheinlichen Zufallsziehungen und jeder möglichen Imposter-Rolle.
Zusätzlich werden alle Gruppengrößen von 3–14, stabile Identitäten und
Folgerunden geprüft. Widget-Tests decken passende Namen und Spielerbilder,
erneutes Aufdecken, Unterbrechungen, lange Namen und 200 Prozent Schrift auf
320-Pixel-Displays ab. Die Semantikprüfung ersetzt keinen echten TalkBack-Test.

Nach der Namenseingabe schließen die Gerätetests die native Android-Tastatur
gezielt und warten bis zu 15 Sekunden auf `viewInsets.bottom == 0`, bevor sie
zum Startbutton scrollen. `pumpAndSettle` allein wartet nicht zuverlässig auf
nachgelieferte Tastaturmetriken. Damit verschiebt sich der sichtbare Bereich
nicht mehr durch eine noch schließende Tastatur zwischen Scrollen und Tippen.

Die gemeinsame Tipp-Hilfe sucht ihr Ziel nach Scrollen und weiteren Frames
erneut und prüft, dass es anklickbar ist und seine Position stabil bleibt.
Verschwindet ein verzögert aufgebautes Sliver-Kind während des Wartens, wird
nur die Suche wiederholt. Die eigentliche Aktion wird genau einmal ausgelöst.
Ein Widget-Regressionstest entfernt den Startbutton zwischen Scrollen und
Tippen vorübergehend: Mit der alten Hilfe schlägt er fehl, mit der neuen
Hilfe wird nach dem Wiedererscheinen genau einmal getippt.

## Lokal ausführen

Seit Ticket 18 folgt auf die bestätigte Abstimmung ein eigener dreisekündiger
Enthüllungs-Countdown. Beide vollständigen Gerätetests prüfen vor Ablauf die
verdeckten Geheimnisse und warten mit der Produktionsuhr auf die Auflösung.
Pausieren bei App-Unterbrechungen und im Verlassensdialog, Screenreader-Schutz,
Doppeltippen und Countdown-Folgerunden werden zusätzlich in Modell-/Widget-Tests
geprüft. Details: [Ticket 18](mvp/ticket-18-enthuellungs-countdown.md).

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

Der Workflow `.github/workflows/ci.yml` hat vier parallele ausführende Jobs
und einen verpflichtenden Gesamtcheck:

- `android`: Formatierung einschließlich `integration_test/`, Analyse,
  Unit-/Widget-Tests und Android-Release-Build.
- `android-game-tests`: zwei Matrixjobs für alle neun Spielabläufe;
  Gruppe 2 führt außerdem die native Fotopipeline aus.
- `android-photo-release`: eigener AOT-/R8-Release-Build der Fotoprobe und
  unveränderte Offline-Prüfung über `scripts/check-photo-release.sh`.
- `android-integration`: prüft mit `always()` beide Jobergebnisse über
  `scripts/require-android-test-groups.sh`. Auch eine übersprungene oder
  fehlgeschlagene Fotoprobe verhindert einen grünen Pflichtcheck.

Alle Emulatorjobs verwenden `.github/actions/setup-android-tests/action.yml`:
Flutter und Java, gesperrte Abhängigkeiten, Lokalisierungen, KVM und Speicherschutz.
Android API 35, `google_apis`, `x86_64`, Pixel-7-Pro-Profil; Animationen aus,
keine gespeicherten Emulator-Snapshots. Die Emulator-Action und externe
Setup-Actions bleiben auf ihre bisherigen Commit-IDs fixiert.

### Speicher für den Android-Runner (Issue #58)

Vor der Tool-Einrichtung entfernt jeder Emulatorjob ungenutzte .NET-,
Boost-, Haskell- und CodeQL-Verzeichnisse. Android-SDK samt NDK, Java,
Flutter und Build-Caches bleiben erhalten. `df -h` protokolliert den Platz
vor und nach dem Aufräumen.

Die AVD-Datenpartition ist ausdrücklich auf **8 GiB** eingestellt. Nach
der Tool-Einrichtung verlangt `scripts/check-android-disk.sh` mindestens
**24 GiB** freien Platz: 8 GiB AVD, 8 GiB für Download und Entpacken des
API-35-Systemimages beziehungsweise Emulator-/SDK-Komponenten und 8 GiB
für Flutter-/Gradle-Builds einschließlich Reserve. Diese konservativen
Budgets sind keine Größenprognose für
jedes SDK-Update; bei geänderten Images anhand der CI-Logs überprüfen.

Die Prüfung erfasst die Dateisysteme von Workspace, Benutzerverzeichnis
(AVD/Gradle), Android-SDK und Runner-Temp. Die Diagnose nennt Pfad sowie
verfügbare und erforderliche KiB. Bei Mangel endet der Job vor dem
Emulatorstart mit einem Fehler, statt in den Boot-Timeout zu laufen.
Die beiden verpflichtenden Jobnamen und die API-35-Testbasis bleiben erhalten.

`bash scripts/test-check-android-disk.sh` prüft dieselbe CLI mit simuliertem
`df`: Ein KiB unter der 24-GiB-Grenze muss mit Speicherdiagnose scheitern,
die exakte Grenze von 24 GiB muss bestehen.
Der Test reserviert keinen echten Plattenplatz und läuft auch im Android-Job.
Der vollständige GitHub-Lauf muss weiterhin alle Spielabläufe, die Fotopipeline
und die Offline-Release-Probe erfolgreich ausführen.

Die Prüfung liegt bewusst in einem eigenen Schritt vor der Emulator-Action:
deren fixierte Version setzt bei Fehlern im `pre-emulator-launch-script`
zwar den Fehlerstatus, versucht anschließend aber trotzdem den Emulatorstart.

Beide Jobs laufen bei Pull Requests gegen `main`, Pushes auf `main` und manuellen
Workflowstarts. Fehler schlagen sich im jeweiligen Job und Gesamtstatus nieder.
Logs enthalten Testnamen, Fehler und Laufzeiten. Es gibt keinen Artefaktupload.
Der Emulatorjob hat 30 Minuten Gesamttimeout und 180 Sekunden Boot-Timeout;
das Warten auf eine ruhige Flutter-Oberfläche ist pro Aktion auf 15 Sekunden
begrenzt. Die tatsächliche CI-Laufzeit muss am ersten GitHub-Lauf gemessen werden.

Seit der weiteren Überarbeitung von Issue #32 entfällt „Gruppe bearbeiten“ aus
allen Rundenansichten. Die Tests öffnen den Verlassensdialog über den Flutter-
Back-Handler. Ein weiterer Android-Ablauf prüft seit #47, dass ungesehene und
teilweise geöffnete Karten bei derselben Person bleiben und erst vollständiges
Ansehen mit anschließendem Loslassen verdeckt weitergibt.
Ein Pixeltest sichert ab, dass die Textfreilegung der tatsächlichen Kurve folgt.
Beim Loslassen prüft die Testhilfe die tatsächliche Einstellung für reduzierte
Bewegung: Bei aktivierten Animationen bleibt der Text zunächst an seiner Position;
bei reduzierter Bewegung muss er sofort verschwinden. Nach dem Schließen ist er
in beiden Fällen entfernt. Die CI deaktiviert Android-Animationen absichtlich und
prüft damit den sofortigen Abschluss, nicht einen künstlich erzwungenen Rücklauf.

Die Testhilfe beginnt Teilöffnungen auf unterschiedlichen Vorhangflächen. Liegt
der Startpunkt hoch, lässt sie vor dem Anschlag los und greift unten neu an,
damit alle Pointer-Ereignisse einschließlich Loslassen im Bildschirm bleiben.

## Grenzen und spätere Ergänzungen

- Diese Tests ergänzen die schnelleren Unit-/Widget-Tests; Varianten der Regeln,
  Fehlerfälle und kleine Displays werden weiterhin dort geprüft.
- Texteingabe erfolgt über Flutter-Test-APIs. Das ist kein Test einer bestimmten
  Android-Tastatur. Dialoge werden über den Flutter-Back-Handler und App-Buttons bedient.
  Native Android-Systemereignisse und echte App-Unterbrechungen sind in dieser
  Suite noch nicht automatisiert.
- `integration_test` bedient keine nativen Systemoberflächen. Für echte
  App-Wechsel, Systemdialoge und weitere Geräteaktionen ist Patrol eine mögliche
  spätere Ergänzung.
- `FLAG_SECURE`, Android-Screenshots und App-Vorschauen werden hier nicht
  überprüft. Der bestehende Fenster-Schutz bleibt aktiv; die Tests benötigen
  keine Bildschirmaufnahmen.
- Layout, Animationen, echter Screenreader und herstellerspezifisches Verhalten
  brauchen weiterhin gezielte Sicht-/Geräteprüfungen. Ein Emulator ersetzt keine
  Prüfung auf einem physischen Android-Gerät.
- Timer und Übergang zur Abstimmung sind ab Ticket 5 enthalten;
  Namensauswahl, Ergebnis und Folgerundenstart ab Ticket 6. Die Folgerunde wird
  bis zum frischen Countdown geprüft; eine zweite volle Spielzeit und deren
  erneute Auswertung prüfen die Widget-Tests mit injizierter Uhr.
  iOS ist hier noch kein Testziel.

## Lokale Erstprüfung am 23.10.2026

- Flutter 3.47.7 auf Windows, Emulator `Medium_Phone_API_36.1` (`emulator-5554`).
  Beide Integrationstests bestanden: etwa 23 Sekunden Testausführung zusätzlich
  zu etwa 125 Sekunden erstem Debug-Build und 3 Sekunden Installation. Das ist
  eine einzelne lokale Messung und keine Vorhersage für GitHub Actions.
- Alle 34 bestehenden Unit-/Widget-Tests bestanden; Flutter-Analyse ohne Befund.
  Formatprüfung und `git diff --check` erfolgreich.

## Ticket-6-Prüfung am 24.10.2026

- Drei Android-Integrationstests auf `Medium_Phone_API_36.1` (`emulator-5554`)
  bestanden: beide Spielausgänge mit echten Zwei-Minuten-Runden, anschließend
  neue Kartenverteilung und frischer Countdown; außerdem der Verlassensablauf.
  Final ca. 4:29 Minuten Testausführung zusätzlich zu Build und Installation.
- Alle 45 Unit-/Widget-Tests sowie Analyse, Formatprüfung und Release-Build
  erfolgreich. Normale Release-App anschließend installiert und gestartet.
- Umfang, lokale Protokolle und Sichtprüfung:
  [Ticket 6](mvp/ticket-6-abstimmung.md).
- Android-Release-APK mit dem endgültigen Buildbefehl erfolgreich gebaut.
  Die generierte Release-Pluginregistrierung enthält das Test-Plugin nicht.
  Der anfängliche Fehler mit `--no-pub` ist durch die oben beschriebene
  Befehlsanpassung behoben. Anschließend bestanden beide Gerätetests auch mit
  dem endgültigen Befehl erneut (34 Sekunden Debug-Build, 23 Sekunden Tests).
- Workflow mit `actionlint` 1.7.12 ohne Befund geprüft. Der neue GitHub-Job ist
  lokal vorbereitet; sein erster echter Lauf auf Ubuntu mit Android API 35 steht
  nach dem Push noch aus.

## Ticket-7-Prüfung am 25.10.2026

- Alle drei Android-Integrationstests bestanden (4:42 Minuten Testausführung,
  zusätzlich 74 Sekunden Debug-Build und vier Sekunden Installation). Beide
  Gewinner und der Abbruchablauf prüfen nun ausdrücklich ein neues Wort;
  Folgerunden prüfen auch den dazugehörigen Hinweis.
- Alle 52 Unit-/Widget-Tests, Analyse, Formatprüfung und Release-Build erfolgreich.
  Alle 100 echten Paare werden in Modellrunden geprüft; zusätzliche Vorratstests
  sichern mehrere vollständige Durchläufe und deren Übergänge ab.
- Normale Release-APK mit exakt dem aktuellen 100er-Katalog installiert und kalt
  gestartet. Prozess/Fenster aktiv, `SECURE` gesetzt und keine Flutter-Fehler oder
  App-Absturzmeldungen in den geprüften Prozesslogs. Testemulator danach beendet.
- Details, lokale Protokolle und noch offene echte Gruppen-Proberunden:
  [Ticket 7](mvp/ticket-7-inhalte.md).

## Ticket-8-Prüfung am 25.10.2026

- Alle 55 Unit-/Widget-Tests bestanden. Drei neue Prüfungen ergänzen
  Android-Touchflächen, beschriftete Aktionen, Textkontraste und vollständige
  Runden bei normaler bzw. 200 % Schrift; zusätzlich Dialogaktionen im Querformat.
- Alle drei regulären Android-Integrationstests mit Produktionsuhr bestanden
  (4:39 Minuten Testausführung zuzüglich Build und Installation).
- Ergänzend echte Android-Tastatureingaben, Home/App-Rückkehr,
  Sperren/Entsperren, System-Zurück und Timerablauf im Hintergrund mit lokalem
  ADB-Treiber geprüft. Dieser temporäre Gerätetest ist unter `build/qa/ticket8/`
  archiviert und nicht Bestandteil des CI-Jobs.
- Release-Build, Installation/Kaltstart, aktiver Fensterschutz und Prozesslogs
  geprüft. Layout-Sichtprüfung mit Roboto auch auf 320 × 568 bei 200 %.
- Details und Grenzen: [Ticket 8](mvp/ticket-8-android-mvp.md).

Grundlagen: [Flutter-Integrationstests](https://docs.flutter.dev/testing/integration-tests),
[Flutter-Testarten und native Grenzen](https://docs.flutter.dev/testing/overview),
[Android Emulator Runner](https://github.com/ReactiveCircus/android-emulator-runner).

## Dynamische Runden und Mehrfachabstimmung (Issue #25)

Die beiden zusätzlichen nativen Abläufe legen sechs beziehungsweise vierzehn
Personen an und verteilen die echten Assets mit unterschiedlichen Hinweisen
zum selben Wort. Die Mehrfachauswahl endet beim öffentlichen Maximum von zwei
beziehungsweise drei Personen. Weitere Personen sind dann deaktiviert;
Abwählen gibt wieder einen Platz frei. Die Grenze folgt nicht der gezogenen
Imposter-Anzahl. Nach 01:30 beziehungsweise 03:30 Startzeit wird in diesen Tests
die injizierte Uhr vorgespult; die beiden dreiköpfigen Komplettabläufe warten weiterhin die echten 45 Sekunden.
Jeder Test wählt eine unschuldige Person an und wieder ab, bestätigt dann exakt
die Imposter, prüft den Gruppensieg nach dem geschützten Countdown und bearbeitet
die Gruppe auf fünf Personen. Die nächste Runde startet mit 01:15.

Modelltests prüfen alle zwölf Gruppengrößen, beide Rollenanzahlen an jeder
variablen Staffel, eindeutige Rollen und Hinweise, exakte Zeitgrenzen sowie
falsche, unvollständige und überzählige Verdachtsmengen. Widget-Tests prüfen
zusätzlich sechs und vierzehn Personen, verdeckte Inhalte im Semantikbaum,
Dialog-/Lifecycle-Schutz, alte Aktionen und Folgerunden; 14 Personen auch bei
320 × 568 und 200 Prozent Schrift.
