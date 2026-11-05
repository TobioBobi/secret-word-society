# CI-Messungen: parallele Release-Fotoprobe

Die vollständige AOT-/R8-Fotoprobe läuft unabhängig von den zwei
Spieltestgruppen auf einem eigenen API-35-Standardrunner. Der verpflichtende
Gesamtcheck verlangt beide erfolgreichen Jobarten. Native Fotopipeline und
normaler App-Release-Build bleiben erhalten.

Als unmittelbare Basis dienen die drei vollständigen Läufe aus
[Issue #64](ci-game-test-measurements.md): 12:01–15:34, Mittel 14:20 bis
alle Pflichtchecks fertig sind; Runner-Zeit im Mittel 29:39.
Die ursprüngliche ungeteilte Pipeline benötigte 19:11 und 23:53 Runner-Zeit.

Die Messungen der neuen Pipeline werden nach vollständigen GitHub-Läufen
hier ergänzt. Jobzeiten enthalten Einrichtung und Nachbereitung; die Summe
der Jobzeiten misst Runner-Zeit, jede einzelne Jobzeit aufgerundet ergibt
Runner-Minuten. Warteschlangen, Cachetreffer, Fehler und Wiederholungen
werden getrennt berücksichtigt. Kleine Stichproben belegen keine langfristige
Zuverlässigkeit. Das Ziel von ungefähr 10–12 Minuten ist keine feste Abnahmegrenze.
