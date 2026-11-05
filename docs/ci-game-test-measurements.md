# CI-Messungen: zwei Android-Spieltestgruppen

## Vergleichsbasis

Erfolgreicher Lauf [42020929635](https://github.com/TobioBobi/secret-word-society/actions/runs/42020929635),
05.11.2026, vor der Aufteilung. GitHub-Jobzeiten einschließlich Einrichtung und
Nachbereitung: Standardjob 4:45, Integration 19:08, insgesamt 23:53 Runner-Zeit
(ohne minutengenaue Abrechnungsrundung). Beide Jobs starteten um 11:40:58 UTC;
alle Pflichtprüfungen waren um 12:00:06 UTC beendet.
Die bisher im Issue genannten 4:42/19:05 messen die eigentlichen Schritte ohne
die letzten Sekunden der Job-Nachbereitung.

Neun Spieltests: 9:38 reine Ausführung, zusätzlich 3:02 Debug-Build/Installation
ab Flutter-Teststart. Native Fotopipeline mit erneutem Build/Installation ca.
0:37, Release-Fotobuild und Offline-Probe ca. 2:55.
Java-/Gradle-, Flutter-SDK- und Pub-Caches trafen. Keine Wiederholung in diesem
Lauf. Ein erfolgreicher Lauf allein belegt keine dauerhafte Zuverlässigkeit.

## Vergleichsläufe

Zwei vollständige `workflow_dispatch`-Läufe von `b46446a` mit identischem
Implementierungsstand, zusätzlich der vollständige PR-Lauf von `2148650`.
Dieser enthält nur die erste Messdokumentation und unterdrückt erwartete
Fehlerausgaben im Gate-Regressionstest; Testauswahl und Testbefehle sind identisch.
Zeiten vom Auslöser bis Abschluss des letzten
Pflichtchecks, Jobzeiten einschließlich Nachbereitung. Runner-Zeit ist die
Summe aller Jobzeiten; gerundete Minuten runden jeden Job einzeln auf.

| Lauf | Alle Pflichtchecks | Standardjob | Gruppe 1 | Gruppe 2 inkl. Fotos | Gesamtcheck | Runner-Zeit | Gerundete Runner-Minuten |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [Basis 42020929635](https://github.com/TobioBobi/secret-word-society/actions/runs/42020929635) | 19:11 | 4:45 | – | 19:08 (alle Tests) | – | 23:53 | 25 |
| [42041222436](https://github.com/TobioBobi/secret-word-society/actions/runs/42041222436) | 15:34 | 5:26 | 9:15 | 14:20 | 0:04 | 29:05 | 32 |
| [42043938899](https://github.com/TobioBobi/secret-word-society/actions/runs/42043938899) | 12:01 | 4:59 | 11:50 | 11:13 | 0:05 | 28:07 | 30 |
| [PR 42044684814](https://github.com/TobioBobi/secret-word-society/actions/runs/42044684814) | 15:26 | 5:15 | 11:13 | 15:11 | 0:06 | 31:45 | 35 |

Erster vollständiger Lauf: alle neun Spieltests erfolgreich, verteilt auf vier
und fünf Tests. Reine Spieltestzeit 4:17 und 5:11; Emulator-Action einschließlich
SDK/Start/Build/Test/Abbau 7:57 und 13:22. Die anfängliche Wartezeit betrug
67 Sekunden, weil der vorherige Lauf noch abgebrochen wurde. Zwischen Ende von
Gruppe 2 und Start des Gesamtchecks lagen weitere drei Sekunden. Java-/Gradle-,
Flutter-SDK- und Pub-Caches trafen auf allen drei ausführenden Jobs.
Native Fotopipeline inklusive Build/Installation 0:42, davon 0:12 reine Tests;
Release-Fotobuild/Offline-Probe zusammen 3:02, davon 0:26 Offline-Probe.
Normaler App-Release-Build 3:18. Keine Testfehler oder Wiederholungen.

Weitere Schrittzeiten:

| Lauf | Reine Spieltests Gruppe 1 / 2 | Emulator-Action Gruppe 1 / 2 | Native Fotopipeline inkl. Build | Release-Fotobuild + Offline-Probe | Normaler Release-Build |
| --- | --- | --- | --- | --- | --- |
| 42043938899 | 5:08 / 4:06 | 10:13 / 10:00 | 0:29 (Tests 0:08) | 1:46 (Offline 0:14) | 3:03 |
| 42044684814 | 5:07 / 4:51 | 10:07 / 13:44 | 0:36 (Tests 0:12) | 3:16 (Offline 0:27) | 3:04 |

In beiden weiteren Läufen trafen ebenfalls Java-/Gradle-, Flutter-SDK- und
Pub-Caches auf allen ausführenden Jobs. Anfängliche Wartezeit: vier Sekunden
im zweiten Lauf, drei bis vier Sekunden im PR-Lauf. Der Gesamtcheck startete
zwei beziehungsweise fünf Sekunden nach dem letzten benötigten Emulatorjob.
Alle neun Spieltests, native Fotopipeline, Offline-AOT-/R8-Probe und der
Standardjob bestanden jeweils ohne Jobwiederholung. Beide Pflichtchecks waren
auch im echten PR-Kontext erfolgreich. Das Repository-Ruleset blieb aktiv,
streng gegen den aktuellen main-Stand und ohne Bypass; die beiden bisherigen
Pflichtchecknamen und deren Bindung an GitHub Actions blieben unverändert.

Die reine Spielzeit ist in beiden Gruppen ähnlich, die langsamere Gruppe
wechselt zwischen den Läufen. SDK-/Emulatorstart und Builds schwanken trotz
Cachetreffern. Die zwei Vergleichsläufe überlappten nicht miteinander;
der zusätzliche PR-Lauf überlappte zeitweise den zweiten Vergleichslauf.
Damit sind die Werte Beobachtungen unter normalen gehosteten Runnerbedingungen,
kein kontrollierter Hardwarebenchmark.

Beobachtet: 12:01–15:34 bis zum letzten Pflichtcheck (Mittel 14:20) gegenüber
19:11 zuvor, also rund 19–37 Prozent kürzer (im Mittel etwa 25 Prozent).
Runner-Zeit 28:07–31:45 (Mittel 29:39) gegenüber 23:53: rund 24 Prozent mehr
im Mittel. Kein zusätzlicher Kostenposten mit den geprüften öffentlichen
Standardrunner-Konditionen. Die kleine Stichprobe belegt keine langfristige
Fehlerquote; sie enthält drei erfolgreiche Vollprüfungen und den unten
dokumentierten abgebrochenen Vorversuch.

Die Vergleichsbasis stammt von vor der inzwischen integrierten sicheren Übergabe
und den Markenassets. Die Assertions der jetzigen Suite sind gegenüber ihrer
unmittelbaren Basis unverändert. Einzelzeiten sind deshalb keine isolierte
Benchmark jedes früheren Testkörpers.

## Abgebrochener Vorversuch

[42040541414](https://github.com/TobioBobi/secret-word-society/actions/runs/42040541414),
`e6430ec`, wurde bewusst abgebrochen. Bei zusätzlicher Quellcodeprüfung der
fixierten Emulator-Action fiel auf, dass sie Skriptzeilen einzeln ausführt. Der
zunächst mehrzeilige bedingte Fotoblock war damit inkompatibel und wurde vor dem
Erreichen dieses Blocks in ein Bash-Skript ausgelagert. Der Abbruch benötigte
anschließend ein Force-Cancel, um den verbleibenden Emulatorjob zu stoppen.
Keine bestandene Vollmessung und kein nachgewiesener App-/Testfehler:
5:26 verstrichen, 15:11 Runner-Zeit (18 gerundete Minuten). Dieser Vorversuch
bleibt Teil der beobachteten Zuverlässigkeit und des Vorbereitungsaufwands.

Das kombinierte Ziel von 10–12 Minuten schließt die separate Optimierung #65
ein und ist keine garantierte Abnahmegrenze für #64 allein. Die Fotoprüfungen
bleiben hier seriell nach Gruppe 2 und verlängern deren kritischen Pfad.
Aus einzelnen erfolgreichen Läufen wird keine dauerhafte Zuverlässigkeit abgeleitet.
