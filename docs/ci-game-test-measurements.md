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

Messung nach dem Push: mehrere vollständige `workflow_dispatch`-Läufe desselben
Implementierungsstands. Kein PR erforderlich. Festhalten: Auslöser bis letzter
Pflichtcheck, Jobzeiten, Test-/Buildzeiten, Summe der Runner-Zeiten, Cachetreffer,
sichtbare Warteschlange, Fehler und Wiederholungen. Ein eventueller Fehlerlauf
bleibt Teil der Beobachtung und wird nicht durch einen erfolgreichen Wiederlauf
ersetzt. Das kombinierte Ziel von 10–12 Minuten schließt die separate Optimierung
#65 ein und ist keine garantierte Abnahmegrenze für #64 allein.
