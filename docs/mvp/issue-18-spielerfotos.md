# Optionale Spielerfotos

Ein Fotobutton pro Person öffnet die Frontkamera mit einem festen ovalen
Positionierungsrahmen. Die Aufnahme erfolgt bewusst per Button. Danach zeigt
die Vorschau einen zufälligen Effekt: große Nase, große Augen, breites Gesicht
oder Strudel. Der auffällige Würfelbutton wählt einen anderen Effekt aus dem
gleichen Set; jede Berechnung verwendet erneut das unverzerrte Ausgangsfoto.
„Neu aufnehmen“ öffnet die Kamera erneut. Erst „Übernehmen“ ersetzt das Bild
in der Gruppe. Zurück und Abbrechen behalten die bisherige Darstellung.

Das Foto gehört zur stabilen Spieler-ID und ersetzt die Darstellung in Gruppe,
Vorhang, Abstimmung und Ergebnis. Es bleibt bei Umbenennen und Folgerunden
erhalten. „Foto entfernen“ stellt exakt den vorherigen Cutouts-Avatar wieder
her. Der Würfel unter einem Foto öffnet sofort einen neu gewürfelten Vorschlag zur Bestätigung; unter einem
Cutouts-Avatar würfelt er weiterhin direkt einen neuen Avatar.

## Verarbeitung und Lebensdauer

- `camera` 0.12.2 mit CameraX 0.7.6+1; `enableAudio: false`.
- `google_mlkit_face_detection` 0.15.1 / Commons 0.13.0, nativ
  `com.google.mlkit:face-detection:16.1.7` mit gebündeltem Modell. Keine
  Bildübertragung oder notwendiger Modelldownload.
- `image` 4.12.0: EXIF-Ausrichtung einrechnen, Metadaten verwerfen und für
  dieselbe Händigkeit wie die Selfie-Vorschau horizontal spiegeln. Der
  Kameraablauf ist auf Hochformat beschränkt; beim Verlassen wird die
  Orientierungsbeschränkung aufgehoben.
- Maximal 768 Pixel lange Quellkante, Gesichtserkennung auf dem normalisierten
  Bild, gesichtsbezogene Verzerrung mit bilinearer Abtastung, weichen Grenzen
  und quadratischem 384-Pixel-Ergebnis. Dekodierung und Effekte laufen in
  separaten Isolates. Kein zusätzlicher Editor und keine Live-Analyse.
- Genau ein Gesicht mit Nase und beiden Augen erforderlich. Kein Gesicht,
  mehrere Gesichter, unvollständige Merkmale und Verarbeitungsfehler liefern
  kurze Hinweise. Ohne Frontkamera oder Kameraberechtigung bleibt Spielen mit
  dem bisherigen Avatar möglich.
- Kamera bei Unterbrechung oder Öffnen der Datenschutzhinweise freigeben und
  bei Rückkehr gegebenenfalls neu öffnen. Versionskennungen verwerfen alte
  Ergebnisse nach Abbruch oder Unterbrechung.
- Quellbild, Merkmale und Ergebnis ausschließlich im Sitzungsspeicher. Keine
  Galerie, Profile oder Exporte. Temporäre Aufnahme-/Detektordateien werden
  auch im Fehlerfall gelöscht. Nach Prozessabbruch entfernt Android beim
  nächsten Activity-Start ausschließlich eigene `CAP<number>.jpg` und
  `sws-photo-*/face.jpg` im privaten Cache. Die dekodierten Bild-Caches werden
  beim Austauschen und Verlassen einer Darstellung verworfen.

## Berechtigungen, Lizenzen und Store-Angaben

Kamera wird erst nach dem bewussten Fotozugang angefordert. Die App funktioniert
auch auf Geräten ohne Kamera (`uses-feature` optional). Mikrofon- und externe
Speicherberechtigungen des Kamera-Plugins werden im Manifest entfernt.

„Datenschutz und Lizenzen“ ist in der Gruppe und im Fotoablauf erreichbar.
Flutter liefert die Lizenz-/Copyrighttexte der aufgelösten Dart-Pakete mit.
`assets/licenses/photo-native.txt` ergänzt die tatsächlich aufgelösten nativen
Komponenten, die mitgelieferten Third-Party-Notices, Apache 2.0 und libyuv BSD.
Google ML Kit, die Modelle und einige Google-Komponenten haben zusätzliche
Bedingungen; die MIT-Lizenz der Flutter-Brücke deckt sie nicht ab.

Nach [Googles ML-Kit-Datenschutzhinweisen](https://developers.google.com/ml-kit/terms)
bleiben Bilddaten und Erkennungsergebnisse auf dem Gerät. SDK-Metriken sowie
Update-/Kompatibilitätsabfragen sind davon getrennt. Die App erklärt dies und
verweist auf Googles Datenschutzhinweise. Offline-Nutzung bedeutet keine
Zusicherung vollständiger Netzwerkfreiheit des SDK.

Vor einer Store-Veröffentlichung die konkreten Angaben in Play Data Safety und
der veröffentlichten Datenschutzerklärung abgleichen: Geräte-/App-Informationen,
SDK-Nutzungs- und Leistungsdaten, Diagnose und Analyse; kein Foto-Upload.
Maßgeblich sind die [Datenhinweise für die tatsächlich verwendeten SDKs](https://developers.google.com/ml-kit/android-data-disclosure).
Hier wurden keine Store-Formulare eingereicht und keine Veröffentlichung vorgenommen.

## Prüfungen und verbleibende Praxisabnahme

- Unit-/Widget-Tests: Effekte reproduzierbar und nicht kumulativ, Ausgabegröße,
  EXIF und Spiegelung, stabile Spieler-ID und Avatar-Rückkehr, vollständiger
  Foto-Spielablauf einschließlich Abstimmung/Ergebnis/Folgerunde, Abbruch und
  verworfene asynchrone Ergebnisse, fehlende Kamera und verweigerte Berechtigung.
- Android-Pipeline: echte native Gesichtserkennung, alle vier Effekte, kein/
  mehrere Gesichter, defekte Dateien und Dateibereinigung. Modell im frisch
  gestarteten Emulator ohne WLAN/mobile Daten geprüft. Die Testvorlage ist
  ein öffentliches NASA-Porträt von Eileen Collins aus
  [scikit-image 0.25.2](https://github.com/scikit-image/scikit-image/blob/v0.25.2/skimage/data/README.txt).
  Die Dart-Fixture ist ausschließlich über den Test-Einstiegspunkt erreichbar
  und gehört nicht zur Release-App.
- Separater lokaler Android-Kameratest mit vorab erteilter Kameraberechtigung:
  virtuelle Frontkamera, Overlay, Aufnahme und Rückkehr nach Unterbrechung.
  CI führt die deterministische native Bildpipeline zusätzlich zur vorhandenen
  Spielablaufsuite aus; der Kamera-Smoke-Test bleibt unabhängig von der
  Kameraausstattung des CI-Emulators ausführbar.
- Sichtprüfung mit geladenen Schriften mit Arial als metrisch ähnlicher Prüfschrift bei 390 × 844/100 Prozent und
  320 × 568/200 Prozent; beschriftete Android-Touchflächen geprüft.

Echte Selfies auf einem physischen Android-Handy, herstellerspezifische
Frontkamera-Ausrichtung/Spiegelung und tatsächliches TalkBack bleiben
Praxisprüfungen. Dabei insbesondere Erstberechtigung/Ablehnung, Drehen des
Handys, Sperren/Entsperren, „Neu aufnehmen“, Austausch/Entfernen und den
ersten vollständigen Offline-Ablauf prüfen.

## Lokaler Abschlussstand vom 03.11.2026

116 Unit-/Widget-Tests, statische Analyse mit fatalen Hinweisen sowie Format-
und Diff-Prüfung erfolgreich. Alle neun bestehenden Android-Spielabläufe auf
API 36.1 bei 320 × 568 und 200 Prozent Schrift bestanden, einschließlich zweier
vollständiger 90-Sekunden-Diskussionen mit Produktionsuhr.

Universelle Release-APK: 89.649.338 Byte, gegenüber 54.630.667 Byte vorher
+35.018.671 Byte (+64,10 Prozent). Der Zuwachs enthält insbesondere die native
Gesichtserkennung für alle drei Android-ABIs und die gebündelten Modelle.
Release-Manifest: Kamera, Netzwerkstatus/Internet für SDK-Komponenten und die
interne AndroidX-Receiver-Berechtigung; kein Mikrofon- oder externer Speicherzugriff.
14 Modelldateien und vollständige Foto-Lizenzhinweise im APK geprüft;
Wortkatalog unverändert, Test-Fixture nicht als Release-Asset enthalten.

Separater finaler Frontkamera-Test bei 200 Prozent Schrift und native Pipeline
mit der finalen Berechtigungsliste erfolgreich. Die gezielte Kaltstart-Bereinigung
wurde mit eigenen verwaisten Aufnahme-/Detektordateien und einer unveränderten
fremden Cache-Testdatei geprüft. Release installiert und kalt gestartet;
Fensterschutz aktiv, geprüfte Prozesslogs ohne App-Fehler.

SHA256: `5DD69CEBB8B5AC1F012FB0B57225F3AE88DDECADE72A8ABC5492C235C7B43AA2`.
