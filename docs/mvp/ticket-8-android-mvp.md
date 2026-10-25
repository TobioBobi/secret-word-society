# Ticket 8 · Party-Look und Android-Abnahme

Stand: 25.10.2026. Branch `codex/ticket-8-party-look`, ausgehend von
`origin/main` (`1b45a91`, einschließlich Ticket 7 aus dem gemergten PR #9).

## Gestaltung und Bedienung

- Die abgestimmte Palette aus Aubergine, Violett und Limette bleibt erhalten.
  Eine kompakte Phasenanzeige mit Symbol ordnet jede Ansicht ein. Bei der
  Kartenverteilung ergänzt ein Balken den beschrifteten Personenfortschritt;
  er zeigt den Anteil der bereits abgeschlossenen Übergaben.
- Eine gemeinsame `PartyCard` vereinheitlicht Konturen, Radien, Innenabstände
  und Vordergrundfarben. Wort und Hinweis verwenden weiterhin dieselbe violette
  Kartenfläche. Verdeckte Karten zeigen nur Schloss und Bedienhinweis.
- Bereit- und Abstimmungshinweise sind kompakter, damit Aktionen und Namen
  früher erreichbar sind. Die Auflösung trennt den Gewinner von den Angaben
  zu Verdacht, Imposter und Wort. Gruppensieg ist limettengrün, Imposter-Sieg
  korallfarben; Text und Symbol erklären das Ergebnis zusätzlich zur Farbe.
- Haupt- und Nebenbuttons verwenden dieselbe Schriftgröße und Gewichtung.
  Der Verlassensdialog übernimmt Oberflächenfarbe, Kontur und Radien der App.
  „Weiterspielen“ ist limettengrün, „Runde verlassen“ korallfarben. Dialogbuttons
  haben mindestens 48 dp Touchfläche, die übrigen Textbuttons mindestens 56 dp.
  Die Namen-Eingabe erhält passende Cursor- und Auswahlfarben.
- Inhalte haben keine festen Texthöhen. Kleine Displays und größere Schrift
  bleiben scrollbar; Dialoginhalte scrollen bei Bedarf oberhalb der Aktionen.
  Dekorative Symbole und der zusätzliche Fortschrittsbalken erzeugen keine
  doppelten Screenreader-Ansagen.

Spielregeln, Wortbestand und Sitzungsverwaltung bleiben unverändert. Es gibt
keine zusätzlichen Abhängigkeiten, Netzwerkzugriffe oder neue Speicherung.
Der native Android-Screenshot-Schutz bleibt durchgehend aktiv. Dieses Paket
enthält keinen Store-Release und keine zusätzlichen Spielmodi oder Sprachen.

## Prüfung

- Alle 55 Unit-/Widget-Tests bestanden, einschließlich der bisherigen
  Sicherheits-, Timer-, Abstimmungs-, Inhalts- und Folgerundentests.
- Drei neue Widget-Tests prüfen beschriftete Touchflächen ab 48 × 48 dp und
  Textkontraste während einer vollständigen Runde, einschließlich geöffneter
  Verlassensdialoge und beider Ergebnisse. Varianten: 390 × 844 mit normaler
  Schrift und 320 × 568 bei 200 %. Zusätzlich bleiben Aufdecken, Abbrechen
  und Verlassen im Querformat auf 568 × 320 bei 200 % erreichbar.
- Gerenderte Flutter-Ansichten mit Roboto und Material-Symbolen auf 390 × 844
  und 320 × 568 bei 200 % visuell geprüft: Gruppe, Übergabe, Wort/Imposterkarte,
  Bereit, Timer, Abstimmung, Auswahl, Gewinner, Ergebnisfelder und Dialog.
  Große Inhalte scrollen; Aktionen bleiben erreichbar. Dies sind lokale
  Widget-Aufnahmen, keine Android-Screenshots. `FLAG_SECURE` wurde nicht
  abgeschaltet. Bilder und Render-Hilfstest liegen ignoriert unter
  `build/qa/ticket8/` und `build/qa/ticket8_visual_test.dart`.

- Alle drei regulären Android-Integrationstests mit echten Assets und
  Produktionsuhr bestanden: beide Gewinner nach vollständigen Zwei-Minuten-Runden,
  verdeckter Folgerundenstart, frischer Countdown und Abbruch/Neustart.
  Emulator `Medium_Phone_API_36.1`, final 4:39 Minuten Testausführung zuzüglich
  66,5 Sekunden Debug-Build und Installation. Log: `build/qa/ticket8/android.log`.
- Zusätzliche native Android-Abnahme bestanden (2:39 Minuten Testausführung):
  Namen über echte Android-Tastatureingaben und Enter anlegen, eine aufgedeckte
  Karte durch Home/App-Rückkehr sowie Sperren/Entsperren verbergen, Android-Zurück
  mit verdecktem Verlassensdialog abbrechen und den vollständigen Timer bei
  125 Sekunden im Hintergrund ablaufen lassen. Bei Rückkehr erscheint direkt
  die Abstimmung ohne Wort/Rolle. Vor jeder Unterbrechung wurde ausdrücklich
  eine tatsächlich aufgedeckte Karte geprüft. Log: `build/qa/ticket8/native.log`.
  Der temporäre Geräte-Hilfstest ist unter `build/qa/ticket8/native_qa_test.dart`
  archiviert; die lokale ADB-Steuerung liegt daneben als `native-driver.ps1`.
  Diese hostabhängige Zusatzprüfung ist nicht Bestandteil der portablen CI-Suite.
- Android-`SECURE` an einer geöffneten Karte bestätigt; die über Android
  aufgenommene App-Fläche bleibt schwarz (`build/qa/ticket8/native-secure.png`).
- Flutter-Analyse mit `--fatal-infos`, Formatprüfung für `lib`, `test` und
  `integration_test` sowie `git diff --check` ohne Befund.
- Release-APK erfolgreich gebaut (47,2 MiB), im Emulator installiert und kalt
  gestartet (`Status: ok`, `LaunchState: COLD`). Vordergrundfenster und Prozess
  aktiv, `SECURE` weiterhin gesetzt. Keine Flutter-Fehler oder App-Abstürze in
  den geprüften Prozesslogs. Der APK-Katalog enthält exakt 100 Paare; die für
  Release generierte Pluginregistrierung enthält das Integrationstest-Plugin
  nicht. Build-/Start-/Prozessprotokolle liegen unter `build/qa/ticket8/`.

## Lokal installierbare APK

`build/app/outputs/flutter-apk/app-release.apk` entsteht mit
`flutter build apk --release`. Der geprüfte Build ist 49.514.400 Byte groß.
Es gilt die bestehende Debug-Signierung für lokale Installation; eine
Store-Veröffentlichung braucht später eine eigene Release-Konfiguration.

## Grenzen

Die Android-Abnahme verwendet den vorhandenen Emulator. Ein physisches Gerät,
ein echter Screenreader und herstellerspezifische Energiesparfunktionen sind
damit nicht geprüft. Die redaktionelle Wort-/Hinweisprüfung aus Ticket 7
ersetzt weiterhin kein echtes Gruppen-Probespiel; dessen
[Prüfliste](ticket-7-inhalte.md) bleibt gültig.
