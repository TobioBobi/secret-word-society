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

Vollständige `workflow_dispatch`-Läufe von `b46446a` mit identischem
Implementierungsstand. Zeiten vom Auslöser bis Abschluss des letzten
Pflichtchecks, Jobzeiten einschließlich Nachbereitung. Runner-Zeit ist die
Summe aller Jobzeiten; gerundete Minuten runden jeden Job einzeln auf.

| Lauf | Alle Pflichtchecks | Standardjob | Gruppe 1 | Gruppe 2 inkl. Fotos | Gesamtcheck | Runner-Zeit | Gerundete Runner-Minuten |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [Basis 42020929635](https://github.com/TobioBobi/secret-word-society/actions/runs/42020929635) | 19:11 | 4:45 | – | 19:08 (alle Tests) | – | 23:53 | 25 |
| [42041222436](https://github.com/TobioBobi/secret-word-society/actions/runs/42041222436) | 15:34 | 5:26 | 9:15 | 14:20 | 0:04 | 29:05 | 32 |

Erster vollständiger Lauf: alle neun Spieltests erfolgreich, verteilt auf vier
und fünf Tests. Reine Spieltestzeit 4:17 und 5:11; Emulator-Action einschließlich
SDK/Start/Build/Test/Abbau 7:57 und 13:22. Die anfängliche Wartezeit betrug
67 Sekunden, weil der vorherige Lauf noch abgebrochen wurde. Zwischen Ende von
Gruppe 2 und Start des Gesamtchecks lagen weitere drei Sekunden. Java-/Gradle-,
Flutter-SDK- und Pub-Caches trafen auf allen drei ausführenden Jobs.
Native Fotopipeline inklusive Build/Installation 0:42, davon 0:12 reine Tests;
Release-Fotobuild/Offline-Probe zusammen 3:02, davon 0:26 Offline-Probe.
Normaler App-Release-Build 3:18. Keine Testfehler oder Wiederholungen.

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
