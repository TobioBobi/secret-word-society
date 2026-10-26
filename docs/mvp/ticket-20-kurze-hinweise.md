# Ticket 20 · Hinweise mit ein bis zwei Wörtern

Stand: 26.10.2026. Vom Nutzer zur Umsetzung beauftragt.

## Inhalte

Alle 100 deutschen Wort-Hinweis-Paare wurden redaktionell geprüft. Die 41
Hinweise mit mehr als zwei Wörtern sind durch kurze Assoziationen ersetzt,
beispielsweise „Achterbahn → Bauchkribbeln“, „Theater → Großer Auftritt“ und
„Karaoke → Schiefe Töne“. Insgesamt bestehen jetzt 31 Hinweise aus einem und
69 aus zwei Wörtern. Die 100 Wörter, ihre IDs und die übrigen 59 Hinweise
bleiben erhalten.

Die Hinweise passen zum geheimen Wort, ohne es zu enthalten, und lassen Raum
für weitere Assoziationen. Wie bei Ticket 7 bleibt die Schwierigkeit in echten
Gruppenrunden zu beurteilen.

## Prüfung

Der neue Katalogtest lädt die ausgelieferten Assets und verlangt für jeden
Hinweis ein bis zwei durch Leerraum getrennte Wörter. Bei einem Fehler nennt
er Paar-ID, geheimes Wort und Hinweis. Mit dem bisherigen Katalog schlug er
wie erwartet bei „Geburtstag → Einmal im Jahr“ fehl.

Alle 59 Unit-/Widget-Tests bestehen mit dem neuen Katalog. Dabei durchlaufen
weiterhin alle 100 Paare eine vollständige Modellrunde mit passenden Karten,
abwechselnden Gewinnern und Folgerunden. Die vorhandenen Prüfungen auf
eindeutige Wörter und IDs sowie auf Hinweise ohne Lösungswort bleiben aktiv.

Flutter-Analyse mit `--fatal-infos`, Dart-Formatprüfung und `git diff --check`
sind sauber. Alle drei Android-Integrationstests mit echten Assets und der
Produktionsuhr bestehen auf `Medium_Phone_API_36.1`: beide Gewinner mit
Folgerunden sowie Verlassen/Abbrechen/Neustart und verdeckte Übergaben.
Die lokale Testausführung dauerte eine Minute zuzüglich Build und Installation.
Protokolle liegen unter `build/qa/ticket20/`.

Tests auf einem physischen Handy und Rückmeldungen aus echten Gruppenrunden
stehen aus. Die Release-APK und der aktuelle GitHub-CI-Status sind im
zugehörigen Pull Request dokumentiert.
