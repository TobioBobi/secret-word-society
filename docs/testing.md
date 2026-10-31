# Android-Integrationstests

Die Tests in `integration_test/app_test.dart` verwenden das offizielle
Flutter-SDK-Paket `integration_test`. Sie starten den regulären App-Einstieg und
bedienen die Flutter-Oberfläche in einer laufenden Android-App. Der Wortkatalog
wird aus den tatsächlich gebündelten Assets geladen, ohne Testkatalog oder
ersetzte Plattformkanäle.

Seit 25.10.2026 ist die Rundendauer für manuelle Handytests vorübergehend auf
10 Sekunden verkürzt. Die Tests verwenden diese echte App-Dauer; die MVP-Regel
bleibt zwei Minuten. Die Rückstellung ist in
[Issue #22](https://github.com/TobioBobi/secret-word-society/issues/22)
vorgemerkt und umfasst auch UI-Texte und Test-Erwartungen.

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

Seit Ticket 23 werden Geheimnisse mit einer gehaltenen Ziehgeste am unteren
Kartengriff angesehen. Die Gerätetests verwenden echte Pointer-Gesten und
lassen vor der getrennten „Weiter“-Aktion los. Widget-Tests prüfen zusätzlich
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
   Genau zwei Personen müssen dasselbe Wort und genau eine Person den dazu
   passenden Hinweis erhalten. Jede Übergabe ist verdeckt; nach der letzten
   Karte erscheint die Bereit-Ansicht. Anschließend die echten 10 Sekunden
   starten und bis zur Abstimmungsansicht warten. Wort und Hinweis bleiben
   dabei verborgen. Ohne Auswahl ist die Bestätigung deaktiviert. Danach den
   tatsächlichen Imposter bzw. gezielt eine andere Person auswählen und
   bestätigen; Gewinner, Verdacht, tatsächlichen Imposter und Wort prüfen.
   „Noch eine Runde“ beginnt bei Person 1 mit verdeckter Karte; alle Karten
   erneut verteilen und einen frischen Countdown bei 00:10 starten. Seit
   Ticket 7 muss die Folgerunde ein anderes Wort mit zugehörigem Hinweis haben.
   Beide Tests brauchen durch die aktuelle Spielzeit jeweils gut 10 Sekunden
   zusätzlich; die Produktionsuhr wird nicht ersetzt.
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

Seit der weiteren Überarbeitung von Issue #32 entfällt „Gruppe bearbeiten“ aus
allen Rundenansichten. Die Tests öffnen den Verlassensdialog über den Flutter-
Back-Handler. Ein vierter Android-Ablauf überspringt alle ungeöffneten Karten:
„Weiter“ muss von Beginn an aktiv sein, ohne irgendein Geheimnis freizulegen.
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
