# Ticket 7 · Deutsche Inhalte und Probespiel

Stand: 25.10.2026. Vom Nutzer nach Umfangserklärung beauftragt. Branch
`codex/ticket-7-deutsche-inhalte`, ausgehend von `origin/main` (`c48b142`,
Ticket 6 aus PR #8 gemergt; per GitHub-API und Fetch geprüft).

## Inhalte

- 100 eigene deutsche Wort-Hinweis-Paare in `assets/words/de.json`, vollständig
  offline. Die 16 vorhandenen Wort-IDs bleiben erhalten; drei ihrer Hinweise
  wurden überarbeitet. Dazu kommen 84 neue Paare.
- Mischung aus Essen, Alltagsgegenständen, Freizeit, Orten, Natur, Tieren und
  gemeinsamen Anlässen. Keine neuen Kategorien oder Einstellungen in der UI.
- Redaktionelle Kriterien: geläufige Begriffe, kurze und verständliche Hinweise,
  nachvollziehbare Verbindung zum Wort und Raum für mehrere Assoziationen.
  Hinweise enthalten das Lösungswort nicht. Beispielsweise „Gitarre → Lagerfeuer“,
  „Fernbedienung → Streit auf dem Sofa“ oder „Puzzle → Geduld in Teilen“.
- Der Import weist doppelte Wörter auch bei anderer Groß-/Kleinschreibung oder
  äußerem Leerraum zurück. Die bisherigen Prüfungen auf eindeutige IDs, leere
  Felder und identische Wörter/Hinweise bleiben bestehen.

Die Inhalte wurden redaktionell geprüft. Eine ausgewogene Schwierigkeit ist
damit noch nicht durch Partyrunden mit echten Personen bestätigt.

## Wortfolge

- Ein neuer `WordDeck` hält den verbleibenden Vorrat ausschließlich im Speicher.
  Jede Ziehung wählt gleichverteilt eines der übrigen Paare. Das entspricht
  einer zufälligen Reihenfolge ohne Zurücklegen.
- Erst nachdem alle 100 Wörter verwendet wurden, beginnt ein neuer Durchlauf.
  Dessen erstes Wort wird aus allen außer dem zuletzt verwendeten gezogen;
  danach stehen wieder alle noch nicht verwendeten Wörter zur Verfügung.
- Die Imposter-Rolle wird unabhängig bei jeder Runde neu ausgelost; dieselbe
  Person darf mehrfach hintereinander Imposter sein.
- `GameSession` behält den Vorrat auch nach „Gruppe bearbeiten“, Entfernen oder
  Hinzufügen von Personen und erneutem Laden unveränderter Katalogdaten.
  „Noch eine Runde“ benutzt denselben Vorrat.
- Eine erfolgreich gestartete Runde verbraucht ein Paar, auch wenn sie vor dem
  ersten Aufdecken abgebrochen wird. Ungültige Starts verbrauchen kein Wort.
  Verdecken, Lifecycle-Wechsel und Navigation innerhalb einer Runde ziehen nichts.
- App-Neustart oder ein anderer Katalog setzen den Vorrat zurück. Ein geänderter
  Katalog wird an Sprache, Reihenfolge und den ID-/Wort-/Hinweis-Feldern erkannt.
  Es gibt keine Speicherung auf dem Gerät und keinen Netzwerkzugriff.
- Ein Katalog mit nur einem Wort bleibt für Tests und Sonderfälle spielbar;
  Wiederholung ist dort unvermeidbar. Ab zwei Wörtern gilt die volle Regel.

`GameRound.start` erzeugt für eigenständige Runden einen neuen Vorrat;
`GameRound.fromDeck` und `newRound` verwenden einen vorhandenen. Rundenstände
bleiben unveränderlich; nur der gemeinsame Ziehvorrat und die Zufallsquelle
werden bei einem Rundenstart weitergeschaltet. Private Karten und Ergebnisse
bleiben wie zuvor phasenabhängig zugänglich.

## Prüfung

- Alle 52 Unit-/Widget-Tests bestanden. Der echte Offline-Katalog wird auf
  genau 100 eindeutige Wörter, eindeutige IDs, nichtleere Felder und Hinweise
  ohne enthaltenes Lösungswort geprüft. Jedes der 100 Paare durchläuft eine
  vollständige Modellrunde, abwechselnd mit Gruppen- und Imposter-Sieg.
- Die neuen Vorratstests prüfen fünf vollständige Durchläufe mit 2, 3, 16 und
  100 Paaren über jeweils 30 Seeds: Vollständigkeit, keine Duplikate und keine
  direkte Wiederholung am Übergang. Dazu kommen Einzelwort-Kataloge,
  reproduzierbare/variierende Reihenfolgen und geänderte Katalogdaten.
- Sitzungstests verbinden Folgerunden, Gruppenänderungen und neu eingelesene
  identische Kataloge über mehrere Durchläufe. Abbruch vor dem Aufdecken,
  ungültige Starts und neue App-Sitzungen sind ebenfalls abgedeckt. Derselbe
  Imposter bleibt in zwei aufeinanderfolgenden Runden ausdrücklich erlaubt.
- Bestehende Widget-Tests prüfen unter anderem die Karten auf 320 × 568
  logischen Pixeln bei 200 % Schrift mit längeren Texten als im neuen Katalog.
- Nach der letzten redaktionellen Änderung erneut alle sechs Katalogtests
  erfolgreich; nach der Konstruktor-Stilkorrektur erneut alle 25 Spielkerntests.
  Flutter-Analyse ohne Befund, Formatprüfung und `git diff --check` sauber.
- Lokale Protokolle unter `build/qa/ticket7-tests.log`,
  `ticket7-catalog-final.log`, `ticket7-game-final.log` und `ticket7-analyze.log`.

- Alle drei Android-Integrationstests auf `Medium_Phone_API_36.1`
  (`emulator-5554`, Kaltstart ohne gespeicherten Snapshot) bestanden. Echte Assets
  und unveränderte Produktionsuhr: beide Gewinner, passende Karten in einer
  Folgerunde mit anderem Wort, frischer Countdown und Abbruch mit anschließendem
  Katalog-Reload ohne Wortwiederholung. Rund 4:42 Minuten Testausführung zuzüglich
  74 Sekunden Debug-Build und vier Sekunden Installation. Protokoll:
  `build/qa/ticket7-android.log`.

- Normale Release-APK erfolgreich gebaut (47,2 MB, lokale Testsignierung gemäß
  bestehender Projektkonfiguration). Der gepackte Katalog wurde direkt aus der
  APK gelesen: 100 Paare, inhaltlich identisch zur Quelldatei. APK:
  `build/app/outputs/flutter-apk/app-release.apk`; Buildprotokoll:
  `build/qa/ticket7-release-build.log`.
- Release-APK im Testemulator installiert und kalt gestartet (`Status: ok`,
  `LaunchState: COLD`). App-Prozess und Vordergrundfenster bestätigt,
  `SECURE` weiter aktiv. Keine Flutter-Fehler oder App-Absturzmeldungen in den
  geprüften Prozesslogs. Start-/Prozess-/Fensterprotokolle:
  `build/qa/ticket7-release-start.log`, `ticket7-release-process.log` und
  `ticket7-release-window.log`. Der nur für diese Prüfung gestartete Emulator
  wurde danach beendet; zum normalen Start weiterhin `start.ps1` verwenden.

Physisches Gerät, echter Screenreader, neue visuelle Abnahme und iOS sind nicht
Teil dieser Prüfung. Echte Gruppen-Proberunden zur Hinweisbalance stehen aus.

## Prüfliste für echte Runden

Mindestens drei Personen spielen mehrere normale Runden. Für auffällige Paare
erst nach der Auflösung gemeinsam notieren, warum der Hinweis zu leicht oder
zu schwer war. Die folgenden Fragen helfen dabei:

- Kannte die Gruppe das Wort? War die Formulierung des Hinweises verständlich?
- Konnte der Imposter einen passenden ersten Beitrag geben, ohne das Wort zu
  kennen? Oder fehlte ihm jeder nachvollziehbare Anhaltspunkt?
- Hat der Hinweis das Wort bereits vor den Beiträgen der anderen praktisch
  verraten? Welche weiteren Begriffe wären mit diesem Hinweis denkbar gewesen?
- Passten mehrere unterschiedliche Beiträge aus der Gruppe zum Wort?
- Machte die Runde Spaß? Ein Sieg oder eine Niederlage allein beweist keine
  gute oder schlechte Hinweisqualität.

Vorlage für Rückmeldungen (keine Spielerdaten erforderlich):

| Paar-ID / Wort | Hinweis | Zu leicht / passend / zu schwer | Beobachtung | Änderungsidee |
| --- | --- | --- | --- | --- |
| | | | | |

Auch mehrere Folgerunden und einmal „Gruppe bearbeiten“ ausprobieren. Bei einer
kleinen Proberunde lässt sich der gesamte 100er-Durchlauf praktisch kaum
ausspielen; dessen Vollständigkeit und Übergangsregel sichern automatisierte
Tests ab. Rückmeldungen aus echten Gruppen stehen noch aus.
