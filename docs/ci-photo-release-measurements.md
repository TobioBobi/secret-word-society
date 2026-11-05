# CI-Messungen: parallele Release-Fotoprobe

Die vollständige AOT-/R8-Fotoprobe läuft unabhängig von den zwei
Spieltestgruppen auf einem eigenen API-35-Standardrunner. Der verpflichtende
Gesamtcheck verlangt beide erfolgreichen Jobarten. Native Fotopipeline und
normaler App-Release-Build bleiben erhalten.

Als unmittelbare Basis dienen die drei vollständigen Läufe aus
[Issue #64](ci-game-test-measurements.md): 12:01–15:34, Mittel 14:20 bis
alle Pflichtchecks fertig sind; Runner-Zeit im Mittel 29:39.
Die ursprüngliche ungeteilte Pipeline benötigte 19:11 und 23:53 Runner-Zeit.

## Vollständige Vergleichsläufe

`workflow_dispatch` mit identischem Implementierungsstand `6cbfa73`,
05.11.2026. Alle Pflichtchecks: Zeit vom Auslöser bis zum Ende des letzten
Pflichtchecks. Jobzeiten enthalten Einrichtung und Nachbereitung; ihre Summe
misst Runner-Zeit. Gerundete Minuten runden jeden Job einzeln auf.

| Lauf | Alle Pflichtchecks | Standardjob | Gruppe 1 | Gruppe 2 inkl. nativer Fotopipeline | Release-Fotoprobe | Gesamtcheck | Runner-Zeit | Gerundete Minuten |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| [42054429386](https://github.com/TobioBobi/secret-word-society/actions/runs/42054429386) | 10:56 | 5:56 | 10:46 | 10:39 | 6:53 | 0:05 | 34:19 | 36 |
| [42056324153](https://github.com/TobioBobi/secret-word-society/actions/runs/42056324153) | 11:21 | 5:51 | 9:49 | 11:06 | 7:00 | 0:06 | 33:52 | 36 |
| [42058319595](https://github.com/TobioBobi/secret-word-society/actions/runs/42058319595) | 11:32 | 4:26 | 11:20 | 11:13 | 5:08 | 0:05 | 32:12 | 36 |

## Schrittzeiten

Emulator-Action einschließlich SDK-Installation, Start, Tests und Abbau.
Reine Spieltests ab dem ersten Testkörper bis zur Erfolgsmeldung;
die native Fotopipeline enthält dort keinen Build. Offline-Probe einschließlich
Installation, Kaltstart und Verarbeitung ab Skriptaufruf im gestarteten Emulator.

| Lauf | Reine Spieltests Gruppe 1 / 2 | Emulator-Action Gruppe 1 / 2 | Native Fotopipeline, reine Tests | AOT-/R8-Build | Release-Emulator-Action | Offline-Probe | Normaler App-Release-Build |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 42054429386 | 5:01 / 4:35 | 9:38 / 9:29 | 0:12 | 3:25 | 2:26 | 1:00 | 3:39 |
| 42056324153 | 4:18 / 4:47 | 8:11 / 10:06 | 0:12 | 3:09 | 2:27 | 1:00 | 3:47 |
| 42058319595 | 5:11 / 5:08 | 9:59 / 10:18 | 0:12 | 2:08 | 1:54 | 0:28 | 2:40 |

Java-/Gradle-, Flutter-SDK- und Pub-Caches trafen in allen drei Läufen auf allen
vier ausführenden Jobs. Die gemeinsame Emulatorvorbereitung dauerte
0:54–1:04 im ersten, 0:54–1:33 im zweiten und 0:49–1:15 im dritten Lauf.
Anfängliche Warteschlangen: 3–4, 3–6 beziehungsweise vier Sekunden.
Der Gesamtcheck startete zwei, drei beziehungsweise drei Sekunden nach dem
letzten benötigten Emulatorjob.
Die Vergleichsläufe liefen nacheinander, ohne sich gegenseitig zu überlappen.

Alle neun Spieltests, die native Fotopipeline, die vollständige native
Offline-AOT-/R8-Fotoprobe und der normale App-Release-Build bestanden jeweils
ohne Fehler, Abbruch oder Jobwiederholung. Die Foto-Release-Prüfung war in
allen drei Läufen deutlich vor den Spieltests abgeschlossen; die langsamere
Spieltestgruppe wechselte zwischen den Läufen.

## Ergebnis und Grenzen

10:56–11:32 bis zum letzten Pflichtcheck, Mittel **11:16**, gegenüber 14:20
nach #64: rund **21 Prozent kürzer**. Gegenüber den ursprünglichen 19:11
sind beide Optimierungen zusammen rund **41 Prozent kürzer**. Alle drei
Beobachtungen liegen im Zielbereich von ungefähr 10–12 Minuten.

Runner-Zeit 32:12–34:19, Mittel **33:28**, gegenüber 29:39 nach #64:
rund **13 Prozent mehr**. Gegenüber den ursprünglichen 23:53 sind es
rund **40 Prozent mehr**. Die aufgerundeten Runner-Minuten betragen jeweils 36.
Der unabhängige Fotojob benötigt eigene Einrichtung, SDK-/Emulatorstart und
einen Release-Build ohne den vorherigen Debug-Build desselben Runners.
Die kürzere Wartezeit geht daher mit mehr gesamter Runner-Zeit einher.

Die unmittelbare #64-Basis und diese Läufe prüfen dieselben App-/Teststände;
App-Code, Testkörper, Assertions und echte Timerwartezeiten sind unverändert.
Die ursprüngliche ungeteilte Basis lag noch vor der sicheren Übergabe und den
Markenassets. Der Vergleich mit ihr misst deshalb die beobachtete Gesamtpipeline,
keinen kontrollierten Benchmark identischer früherer Testkörper.

Die aktive strikte Repository-Regel mit beiden bisherigen Pflichtchecknamen,
GitHub-Actions-Bindung und ohne Bypass blieb unverändert. Der Gesamtcheck
verlangt jetzt zusätzlich das erfolgreiche Ergebnis der Release-Fotoprobe;
sein Regressionstest weist deren Fehler, Abbruch, Überspringen und fehlendes
Ergebnis auch bei erfolgreichen Spieltests ab.

Kleine Stichproben belegen keine langfristige Zuverlässigkeit. SDK-/Emulatorstart
und Builds schwanken trotz Cachetreffern. Das Ziel von ungefähr 10–12 Minuten
ist keine feste Abnahmegrenze. Der zusätzliche Standardrunner erhöht die
Runner-Minuten; im geprüften öffentlichen Repository bleibt er nach den
[GitHub-Konditionen](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job)
kostenlos. Es werden keine größeren oder selbst betriebenen Runner verwendet.
