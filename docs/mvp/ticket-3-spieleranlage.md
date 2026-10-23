# Ticket 3 · Spieler anlegen und Runde starten

Grundlage: [Ablauf und Gestaltung](ticket-1-ablauf-design.md) sowie der
[Spielkern aus Ticket 2](ticket-2-spielkern.md).

## Bedienbarer Umfang

- Deutsche Spieleranlage im abgestimmten Aubergine-/Violett-/Limette-Look.
- Namen per Plus-Button oder Tastaturaktion hinzufügen, einzelne Personen über
  beschriftete Entfernen-Aktionen löschen. Reihenfolge bleibt erhalten.
- Namen werden getrimmt. Leere/aus Leerzeichen bestehende Namen sowie Duplikate
  ohne Unterscheidung von Groß-/Kleinschreibung werden mit Inline-Hinweisen
  abgelehnt. Keine künstliche Begrenzung von Gruppe oder Namenslänge.
- Anzahl und fehlende Personen werden angezeigt. „Runde starten“ ist erst ab
  drei Personen aktiv und während des Ladens gegen Mehrfachstarts gesperrt.
- Der Start lädt den gebündelten deutschen Katalog und ruft `GameRound.start`
  auf. Wort und Imposter werden vom bestehenden Spielkern zufällig bestimmt.
  Die Oberfläche zeigt nur „Handy an {Name}“, „Person 1 von {Anzahl}“ und eine
  verdeckte Karte. Geheimnisse, Rollen und Timer sind noch nicht sichtbar.
- Ladefehler lassen die Gruppe unverändert; ein erneuter Start ist möglich.
- „Gruppe bearbeiten“ und Android-Zurück führen aus dieser ersten Übergabe
  direkt zur bestehenden Gruppe. Dabei wird die angefangene Runde verworfen.
  Erneutes Starten erzeugt eine neue verdeckte Runde.
- Gruppe und Runde bleiben ausschließlich im Speicher der laufenden App.
  Ein neuer App-Prozess beginnt leer; Hintergrund-/Vordergrundwechsel innerhalb
  desselben Prozesses löschen die Gruppe nicht.

Die erste Übergabe ist die Schnittstelle für Ticket 4. Aufdecken/Weiterreichen,
Schutz bei App-Wechseln und das Verlassen mit Rückfrage folgen dort. Countdown,
Abstimmung und die vollständig spielbare Folgerunde folgen in Tickets 5–6.

## Aufbau

`GameSession` hält Gruppe, stabile Spieler-IDs und aktuellen Rundenstand ohne
Flutter-Abhängigkeit. Entfernte IDs werden in derselben Sitzung nicht erneut
vergeben; ähnliche Namen und wieder hinzugefügte Personen bleiben eindeutig.
Die UI verwaltet Eingabefeld, Fokus, Scrollposition und asynchronen Ladestatus.
Sie hält keine Kopien aufgedeckter Geheimnisse und speichert keine Sitzungsdaten.

Die Formularansicht ist scrollbar; bei vielen Personen wird die Namensliste
bedarfsgesteuert aufgebaut. Namen und Aktionsbeschriftungen dürfen umbrechen.
Entfernen-Aktionen haben mindestens 48 dp, Hauptaktionen mindestens 56 dp
Touchfläche. Phasenüberschriften erhalten den Fokus; Fehler und Spieleranzahl
nutzen semantische Statusmeldungen. UI-Texte liegen weiterhin in `app_de.arb`,
Wortdaten getrennt im deutschen Asset. Es gibt keine neue Paketabhängigkeit.

## Automatisierte Prüfung

Die Tests decken zusätzlich zum bestehenden Spielkern ab:

- Namensprüfung, Reihenfolge, stabile IDs, Entfernen/Wiederhinzufügen und große Gruppen.
- Mindestspielerzahl, Rundenstart mit echtem Spielkern, verdeckter Anfangszustand
  ohne laufenden Timer und unveränderlicher Runden-Snapshot.
- Gruppe bearbeiten, Android-Zurück und leere neue App-Sitzung.
- Bedienung über Plus-Button und Tastaturaktion, Aktivierung/Deaktivierung des Starts.
- Katalogfehler, erneutes Laden, Mehrfachstart-Sperre und Entfernen der Ansicht
  während eines noch laufenden Ladevorgangs.
- Keine Wörter oder Hinweise im Accessibility-Baum der verdeckten Übergabe.
- 320 × 568 logische Pixel, 200 % Schrift, simulierte Bildschirmtastatur, langer
  ungetrennter Name und zwölf Personen: Bedienelemente bleiben per Scrollen erreichbar.

Prüfergebnis: alle 28 Tests bestanden, `flutter analyze --no-pub` ohne Befund.
Nach dem Umstellen des Accessibility-Tests auf die aktuelle Flutter-API wurden
die fünf Widget-Tests und die Analyse erneut erfolgreich ausgeführt.

## Android-Prüfung

Die Debug-APK wurde lokal gebaut, im Emulator `Medium_Phone_API_36.1` installiert
und gestartet. Spieleranlage, gefüllte Gruppe und verdeckte Übergabe wurden
per Screenshot visuell geprüft. Über die Android-Bedienung zusätzlich geprüft:

- Leere Eingabe, Duplikat `Anna`/`aNNa`, Hinzufügen per Plus und Tastaturaktion.
- Start erst ab drei Personen; nach Entfernen einer Person wieder deaktiviert.
- Wiederhinzufügen, Rundenstart und erste verdeckte Übergabe an Anna.
- Android-Zurück sowie „Gruppe bearbeiten“ erhalten die Namen; erneuter Start
  beginnt wieder bei Person 1 mit verdeckter Karte.
- App-Wechsel erhält die Gruppe im selben Prozess. Vollständiges Beenden und
  erneutes Starten beginnt mit leerer Gruppe.

Keine Flutter-/Android-Laufzeitfehler in den geprüften Logs des App-Prozesses.
Lokale Nachweise liegen unter `build/qa/ticket-3-{setup,group,handoff}.png`,
`ticket-3-handoff-ui.xml` und `ticket-3-app.log` (nicht versioniert).

Der zunächst aus einem Snapshot fehlerhaft gestartete Emulator musste ohne
Snapshot neu gestartet werden; danach funktionierte die Prüfung. Kleine
Displays und 200 % Schrift wurden automatisiert geprüft, nicht zusätzlich
visuell auf Android. Ein physisches Gerät, ein echter Screenreader und eine
vollständige Spielrunde sind noch nicht Bestandteil dieser Prüfung.
