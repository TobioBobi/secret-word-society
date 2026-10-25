# Ticket 6 · Abstimmung, Auflösung und neue Runde

Stand: 24.10.2026. Branch `codex/ticket-6-abstimmung`, ausgehend vom aktuellen
`origin/main` (`ea5e458`, einschließlich Ticket 5 aus PR #7).

Fortschreibung vom 25.10.2026: Die unten dokumentierten erlaubten
Wortwiederholungen werden durch [Ticket 7](ticket-7-inhalte.md) ersetzt.
Imposter-Wiederholungen bleiben möglich.

## Verhalten

- Nach Ablauf der zwei Minuten wählt eine Person den gemeinsam mündlich
  verdächtigten Namen aus. Bei Gleichstand stimmt die Gruppe erneut mündlich ab.
- Große Radio-Zeilen mit Namen; auch größere Gruppen bleiben scrollbar.
  Die Auswahl ist bis zur Bestätigung änderbar. Wort und Rolle bleiben verborgen.
- Ohne Auswahl ist „Person auswählen“ deaktiviert. Mit Auswahl heißt der Button
  „{Name} verdächtigen“ und öffnet unmittelbar die Auflösung.
- „Erwischt!“ und Gruppensieg bei richtigem Verdacht, „Gut geblufft!“ und
  Imposter-Sieg bei falschem Verdacht. Angezeigt werden euer Verdacht, der
  tatsächliche Imposter und das geheime Wort.
- „Noch eine Runde“ behält Namen und Reihenfolge, lost Wort und Imposter erneut
  aus und beginnt verdeckt bei Person 1. Auswahl, Ergebnis und Timer werden
  zurückgesetzt; die zwei Minuten starten erst wieder nach allen Karten und
  bewusster Betätigung von „2 Minuten starten“.
- Zufällige Wiederholungen von Wort oder Imposter bleiben möglich, wie im
  Spielkern und in Ticket 1 vorgesehen. Wiederholungsvermeidung gehört ggf.
  zum Inhaltsausbau in Ticket 7.
- Während der Abstimmung fragen „Gruppe bearbeiten“ und Android-Zurück nach dem
  Verlassen. Abbrechen behält die Auswahl. Auf der abgeschlossenen
  Ergebnisansicht führen beide direkt zur Gruppe mit vorhandenen Namen
  (Bedienentscheidung: Es gibt keine laufende Runde mehr zu verwerfen).
- App-Unterbrechungen behalten Auswahl bzw. Ergebnis. Aktionen während einer
  Unterbrechung oder eines Verlassensdialogs sowie alte und mehrfach ausgelöste
  Aktionen werden ignoriert. Ein Prozessneustart beginnt weiterhin leer.

## Umsetzung

`GameSession` bindet `selectSuspect`, `confirmSuspect` und `newRound` aus dem
bestehenden unveränderlichen Spielkern an. Die Ansicht verwendet eine native
Flutter-`RadioGroup` mit lazily aufgebauten `RadioListTile`-Zeilen sowie eine
Ergebniskarte und beschriftete Ergebnisfelder. Die Überschrift erhält beim
Phasenwechsel den Fokus; bei Namensauswahl bleibt die Scrollposition erhalten.

Neue Texte liegen in `app_de.arb`; Dart-Lokalisierungen werden generiert.
Keine neue Abhängigkeit und keine dauerhafte Speicherung. Androids bestehendes
`FLAG_SECURE` bleibt durchgehend aktiv.

## Prüfung

- Alle 45 Unit-/Widget-Tests bestanden; Flutter-Analyse, Formatprüfung und
  `git diff --check` ohne Befund.
- Fünf neue Widget-Tests prüfen beide Gewinner, fehlende und geänderte Auswahl,
  Geheimnisschutz bis zur Bestätigung, Abbruch/Verlassen, Android-Zurück,
  Unterbrechungen, Mehrfachtippen und alte Aktionen. Beide Gewinnerabläufe
  spielen danach eine vollständige zweite Runde mit zurückgesetzter Auswahl
  und neuem Countdown. Ein App-Neustart beginnt wieder mit leerer Gruppe.
- Ausgewählte Radio-Semantik und Überschriftenfokus geprüft. Zwölf Personen
  einschließlich langem Namen, Auswahl, Auflösung und Folgerundenstart auf
  320 × 568 logischen Pixeln bei 200 % Schrift ohne Layoutfehler geprüft.
- Android-Integrationstests um beide Gewinner und Folgerunden bis zum erneut
  gestarteten Countdown erweitert; echte Assets und unveränderte Produktionsuhr.
  Alle drei Tests auf `Medium_Phone_API_36.1` (`emulator-5554`) bestanden, auch
  nach der abschließenden Begrenzung der Radio-Semantik auf die Abstimmung.
  Finaler Lauf ca. 4:29 Minuten Testausführung zuzüglich Build und Installation;
  Protokoll unter `build/qa/ticket6-android.log`.
- Release-APK erfolgreich gebaut (47,2 MB). Gerenderte Flutter-Ansichten mit
  Roboto-Schrift auf 390 × 844 Pixeln visuell geprüft: Abstimmung, ausgewählte
  Person und Bestätigung sowie beide Gewinner mit Ergebnisfeldern und Aktionen.
  Zusätzlich Ergebnisansicht auf 320 × 568 Pixeln bei 200 % Schrift gerendert;
  weitere Inhalte sind durch Scrollen erreichbar. Lokale Aufnahmen und
  Render-Hilfstest liegen ignoriert unter `build/qa/ticket6/` bzw.
  `build/qa/ticket6_visual_test.dart`. Dies sind Widget-Aufnahmen, keine
  Android-Screenshots; der native Screenshot-Schutz wurde nicht abgeschaltet.
- Normale Release-App anschließend im Emulator installiert und kalt gestartet
  (`Status: ok`). App-Prozess und sichtbares Fenster bestätigt; `SECURE` weiterhin
  aktiv. Keine Flutter-Fehler oder App-Abstürze in den geprüften Prozesslogs.
  Native Emulator-/Grafikmeldungen einschließlich der bekannten
  `ashmem`-Deprecation sind keine App-Testfehler. Startprotokoll unter
  `build/qa/ticket6-release-start.log`, Buildprotokoll unter
  `build/qa/ticket6-release-build.log`.

Physisches Gerät, echter Screenreader und iOS sind nicht Teil dieser Prüfung.
