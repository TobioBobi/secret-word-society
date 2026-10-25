# Ticket 2 · Spielkern und deutscher Startwortbestand

Stand: 23.10.2026. Grundlage ist der [Ablauf aus Ticket 1](ticket-1-ablauf-design.md).
Fortschreibung vom 25.10.2026: [Ticket 7](ticket-7-inhalte.md) erweitert den
damaligen Startbestand auf 100 Paare, validiert auch eindeutige Wörter und ersetzt
die hier beschriebenen erlaubten Wortwiederholungen durch einen Sitzungsvorrat.
Dieses Paket implementiert die Spiellogik. Spielbare Flutter-Ansichten folgen
in Tickets 3–6; der Startbildschirm bleibt ein nun deutscher Platzhalter.

## Modelle und Zuständigkeiten

- `Player`: unveränderliche ID und getrimmter Anzeigename; keine leeren Felder.
- `WordPair` / `WordCatalog`: Wort, Hinweis, stabile Inhalts-ID und Sprachcode.
  Daten sind unabhängig von Flutter und von UI-Texten. Der JSON-Import lehnt
  fehlende/falsch typisierte Felder, Leerwerte, doppelte IDs und identische
  Wörter/Hinweise ab; Fehler werden als `FormatException` gemeldet.
- `loadWordCatalog`: lädt ausschließlich installierte Asset-Dateien. Aktuell
  `assets/words/de.json` mit 16 eigenen deutschen Paaren. Kein Netzwerkzugriff,
  keine weitere Sprache und kein stiller Ersatz bei fehlendem Katalog.
- `GameRound`: unveränderlicher Rundenstand mit geschützter Phasenfolge.
  Aktionen geben den neuen Stand zurück; die aufrufende Oberfläche ersetzt
  damit ihren aktuellen Stand. Zufallsquelle ist für Tests injizierbar.

Eine Runde benötigt mindestens drei Personen und eindeutige IDs/Namen
(Namen ohne Unterscheidung von Groß-/Kleinschreibung). Es gibt keine künstliche
Spielerobergrenze. Die Liste wird kopiert und ist von außen nicht veränderbar.

## Ablauf und Geheimnisse

`handoff → secret → handoff … → ready → discussion → voting → result`

- Start zieht genau ein Paar und genau einen Imposter zufällig. Jede andere
  Person sieht dasselbe Wort; der Imposter sieht ausschließlich den Hinweis
  und seine Rolle. Reihenfolge entspricht der übergebenen Spielergruppe.
- `revealSecret()` deckt für die aktuelle Person auf. Nur in `secret` liefert
  `currentSecret` eine Rolle und einen Text. Der ausgewählte Katalogeintrag und
  die Imposter-Zuordnung sind privat; `result` ist vor der Ergebnisphase `null`.
- `concealSecret()` verdeckt dieselbe Person erneut, etwa bei Unterbrechungen.
  `hideAndAdvance()` verdeckt und wechselt atomar zur nächsten Person, nach der
  letzten zu `ready`. Es gibt keine Aktion zur vorherigen Person.
- `startDiscussion(now)` ist ausschließlich in `ready` erlaubt. Die Dauer ist
  120 Sekunden. `remainingDiscussionTime(now)` berechnet aus dem Endzeitpunkt;
  `advanceTime(now)` wechselt bei Erreichen/Ablauf zur Abstimmung. Aufrufe durch
  Timer/Lifecycle werden erst in Ticket 5 angebunden.
- `selectSuspect(id)` akzeptiert nur Rundenmitglieder und erlaubt Umwählen.
  `confirmSuspect()` setzt eine Auswahl voraus und gibt das Ergebnis frei:
  tatsächlicher Imposter, gewählte Person, Wort und Sieger gemäß MVP-Regel.
- `newRound()` ist nach dem Ergebnis erlaubt. Gleiche Gruppe und gleicher
  Katalog, neue Zufallsziehungen, erste Person, verdeckt, kein Verdacht/Ergebnis,
  kein Endzeitpunkt, wieder 120 Sekunden. Zufällige Wiederholungen sind erlaubt.

Falsche Aktionsreihenfolgen werfen `StateError`, ungültige Spieler/IDs
`ArgumentError`. Diese Entwicklerfehler sind keine UI-Texte. Validierung mit
deutschen Bedienhinweisen folgt in den jeweiligen Ansichten.

Die private Dart-API verhindert versehentliches Auslesen über normale Getter.
Die Oberfläche muss alte aufgedeckte Rundenstände verwerfen und darf sie nicht
in Navigation, Logs oder Wiederherstellungsdaten behalten. Lifecycle-Anbindung,
Zurück-Navigation und nativer Screenshot-/Vorschauschutz gehören zu Ticket 4.

## Anbindung ab Ticket 3

```dart
final catalog = await loadWordCatalog();
var round = GameRound.start(players: players, catalog: catalog);
round = round.revealSecret();
final secret = round.currentSecret!;
// Nur diese Rolle und diesen Text auf der privaten Karte anzeigen.
round = round.hideAndAdvance();
// Alte private Karte entfernen und neuen Stand darstellen.
```

Keine Sitzungsdaten werden gespeichert. Die Oberfläche hält Gruppe und
Rundenstand im Speicher; beim Bearbeiten/Verlassen verwirft sie die Runde und
behält bei Bedarf die Gruppe. Das Rundenmodell implementiert keine Navigation.

## Sprache und Inhalte

UI-Texte liegen in `lib/l10n/app_de.arb`. Flutter `gen-l10n` erzeugt daraus die
eingebundenen `AppLocalizations`. `MaterialApp` nutzt die Delegates und die
verfügbaren Locales; bisher nur Deutsch, ohne Sprachwahl. Künftige UI-Texte
werden in der ARB-Datei ergänzt, Wörter in einem separaten Sprachkatalog.

Die Hinweise sind ein kleiner eigener Testbestand. Ob sie in Partyrunden
ausgewogen sind, wird erst beim Probespielen und Inhaltsausbau in Ticket 7
bewertet; Wiederholungsvermeidung ist noch nicht eingebaut.

## Prüfungen

`flutter analyze` ist ohne Befund durchgelaufen; `flutter test` hat alle 19 Tests
erfolgreich ausgeführt. Geprüft werden:

- Mindestzahl, Namen/IDs, unveränderliche Gruppen und größere Gruppen.
- Genau einen Imposter sowie konsistente Wort-/Hinweis-Verteilung über viele
  reproduzierbare Ziehungen mit unterschiedlich großen Gruppen.
- Verdecken, Weiterreichen und alle unzulässigen Phasenwechsel.
- Bewussten Timerstart, Ablaufgrenze und Rückkehr nach längerer Unterbrechung.
- Auswahl/Umwahl, beide Gewinner und vollständiges Zurücksetzen von Folgerunden,
  einschließlich erneuter Zufallsziehungen und erlaubter Wiederholungen.
- Beschädigte Kataloge, fehlende/unpassende Sprachdaten und echtes Asset-Laden.
- Vollständige Runde mit gebündelten deutschen Inhalten und deutschen Starttext.

Zusätzlich lokal auf dem Android-Emulator `Medium_Phone_API_36.1` geprüft:
Debug-APK erfolgreich gebaut und installiert, App gestartet, Vordergrundaktivität
und laufender Prozess bestätigt. Screenshot des deutschen Startbildschirms
(„Hallo, Welt!“) visuell geprüft; keine Flutter-/Android-Laufzeitfehler in den
geprüften App-Logs. Lokales Bild: `build/qa/ticket-2-android-start.png`.

Der Spielkern ist automatisiert getestet; die Android-Prüfung deckt den App-Start
ab. Native Spielansichten, echtes Android-Lifecycle-Verhalten einer Runde und ein
vollständiges Spiel am Gerät sind noch nicht Bestandteil dieser Abnahme.
