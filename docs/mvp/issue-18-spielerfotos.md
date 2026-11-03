# Optionale Spielerfotos

Ein Fotobutton pro Person öffnet die Frontkamera mit einem festen ovalen
Positionierungsrahmen. Die Aufnahme erfolgt bewusst per Button. Danach zeigt
die Vorschau einen zufälligen Effekt aus dem erweiterten Set mit 14 Varianten.
Der auffällige Würfelbutton wählt einen anderen Effekt aus dem
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

Universelle Release-APK: 89.649.218 Byte, gegenüber 54.630.667 Byte vorher
+35.018.551 Byte (+64,10 Prozent). Der Zuwachs enthält insbesondere die native
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

SHA256: `B6A7E7B01E38BA015F730DC0E327379CCDE591008D661F5462DB983DEC08C5BA`.

## Korrektur: Gesichtserkennung scheitert nur im Release

Die erste ausgelieferte APK scheiterte bereits beim Start der Gesichtserkennung.
Die vorherigen nativen Verarbeitungstests liefen im Debug-Modus; die
Release-Abnahme prüfte nur Installation und App-Start. Damit war die tatsächliche
Release-Bildverarbeitung noch nicht abgesichert.

Der Fehler wurde mit demselben bekannten Testporträt in einer AOT-/R8-APK
reproduziert: `NoSuchMethodException` für die parameterlosen Konstruktoren von
`FaceRegistrar`, `CommonComponentRegistrar` und `VisionCommonRegistrar`, danach
ein `PlatformException` bei der Detektorinitialisierung. Das geschieht vor der
Gesichtserkennung und hat nichts mit der Position im Rahmen zu tun.

`android/app/proguard-rules.pro` erhält die per Reflection aus dem Manifest
geladenen `ComponentRegistrar`-Klassen samt öffentlichem Standardkonstruktor.
Die übrige Optimierung bleibt aktiv. Der gleiche Release-Test verarbeitet das
Porträt danach ohne Netzwerk erfolgreich mit allen vier Effekten.

`integration_test/photo_release_probe.dart` ist ein separater Test-Einstiegspunkt,
der Release-Modus voraussetzt. Er gehört nicht zum normalen App-Einstiegspunkt.
Die CI baut und startet ihn zusätzlich zu den Debug-Integrationstests:

```sh
flutter build apk --release --target integration_test/photo_release_probe.dart
bash scripts/check-photo-release.sh build/app/outputs/flutter-apk/app-release.apk emulator-5554
```

Das Skript schaltet Netzwerkdienste im Testemulator aus, wartet auf ein explizites
Ergebnis und schlägt bei Fehler oder Zeitüberschreitung fehl. Danach für die
eigentliche Testverteilung stets wieder `flutter build apk --release` mit dem
normalen Einstiegspunkt bauen.

Fehlermeldungen unterscheiden jetzt Kameraaufnahme, unlesbares Bild,
fehlgeschlagenen Start der Gesichtserkennung und Effektberechnung. Nicht
erkannte Gesichter bzw. fehlende Merkmale behalten ihre eigenen Hinweise.
Native Initialisierungsfehler und defekte Bilder werden mit unterschiedlichem
Fehlergrund getestet; temporäre Dateien werden in beiden Fällen bereinigt.

Abnahme der Korrektur: 117 Unit-/Widget-Tests, Analyse und Format-/Diff-Prüfung
erfolgreich. Dieselbe optimierte Release-Probe zeigt vor dem Fix den
Initialisierungsfehler und danach offline erfolgreiche Erkennung sowie alle
vier Effekte. Das neue CI-Skript wurde lokal erfolgreich ausgeführt; sein
Remote-Lauf steht noch aus. Die normale Release-App wurde anschließend wieder
gebaut; die neun unveränderten Spielabläufe wurden für diese Korrektur nicht
nochmals ausgeführt. Der erneute Praxistest auf dem gemeldeten Handy bleibt offen.

Aktualisierte Release-APK: 89.649.218 Byte; SHA256:
`40853B3715AFAEC607AA6F99D800A9B7F9144087F38A0D2A76F14F7FFE756025`.

## Erweiterung auf 14 Effekte und zufällige Stärken

Am 03.11.2026 vollständig beauftragt: zusätzlich zu großer Nase, großen Augen,
breitem Gesicht und Strudel alle zehn vorgeschlagenen Effekte implementieren:

| Effekt | Umsetzung |
| --- | --- |
| Alien | Große Augen, kleiner Mund, schmaleres Kinn |
| Hamsterbacken | Aufgeblähte Wangen mit kleinerem Mund |
| Riesengrinsen | Horizontal stark verbreiterter Mund |
| Eierkopf | Langes, schmales Gesicht |
| Quetschkopf | Kurzes, breites Gesicht |
| Schiefgesicht | Asymmetrische Gesichtshälften und ein größeres Auge |
| Mini-Gesicht | Verkleinerte Gesichtszüge innerhalb des Kopfes |
| Spiegelgesicht | Linke oder rechte Gesichtshälfte doppelt gespiegelt |
| Wackelpudding | Weiche wellenförmige Verzerrung |
| Fischauge | Großflächige Wölbung der Gesichtsmitte |

Bei jedem Vorschlag wird für alle 14 Effekte gleichverteilt eine Stärke zwischen
75 und 125 Prozent der effektspezifischen Grundstärke gezogen. Spiegel- und
Schiefgesicht variieren zusätzlich die Seite. Stärke und Seite bleiben als
`PhotoVariation` beim gerenderten Vorschlag gespeichert. Übernehmen, Umbenennen,
Rundenwechsel und die Darstellung in verschiedenen Ansichten ändern den Effekt
nicht. Es gibt weiterhin keinen zusätzlichen Regler oder Editor.

Mundbezogene Effekte verwenden nach Möglichkeit die erkannten Mundwinkel.
Falls diese fehlen, wird die Position aus der vorhandenen Gesichtsgeometrie
abgeleitet; weitere notwendige Erkennungsmerkmale kommen nicht hinzu.
Alle Rezepte sind weiche inverse Koordinatentransformationen. Jeder Pixel wird
einmal aus dem unveränderten Ausgangsfoto abgetastet, auch bei kombinierten
Augen-/Mund-/Kinn-Effekten. Ausgabeauflösung und Sitzungsspeicherung bleiben gleich.

Tests prüfen alle 14 Effekte bei beiden Stärkegrenzen, unterschiedliche Ergebnisse,
Wiederholbarkeit gleicher Einstellungen, unveränderte Ausgangsdaten, beide
Spiegelrichtungen sowie Reichweite und Variation der Zufallswerte. Die native
Pipeline prüft die zufällige Verarbeitung jedes Effekts. Die AOT-/R8-Release-Probe
prüft alle 28 Kombinationen aus Effekt und Grenzstärke und beide Spiegelrichtungen.
Die Effekte wurden bei 75, 100 und 125 Prozent visuell geprüft; die Vorschau
zusätzlich bei normaler und 200-Prozent-Schrift mit beschrifteten Touchflächen.

Abnahme der Erweiterung: 119 Unit-/Widget-Tests, Analyse, Format-/Diff-Prüfung,
28 Offline-Kombinationen in der AOT-/R8-Release-Probe und nativer Foto-Pipelinetest
mit allen 14 zufälligen Varianten erfolgreich. Die normale Release-App wurde
gebaut und auf Kaltstart/Fensterschutz geprüft. Die unveränderten neun
Spielabläufe wurden nicht nochmals ausgeführt. Remote-CI, tatsächliches
TalkBack und der erneute Test der neuen Effekte auf dem physischen Handy
bleiben getrennte Prüfungen. Keine zusätzlichen Abhängigkeiten oder Berechtigungen.

Release-APK: 89.731.138 Byte; SHA256:
`A74526BD60056B075B1976BBD185229B6531B50CA7C1CFA6231E02CAE6B479BD`.

## Review-Korrekturen für PR #44

Die Rückkehr aus `inactive` baut die vorhandene Fotovorschau jetzt sofort neu
auf. „Übernehmen“ ist nach dem Zurückkehren ohne zusätzliches Würfeln wieder
aktiv. Der Regressionstest rendert ausdrücklich einen inaktiven Zwischenframe
und übernimmt danach dasselbe Foto. Vor der Korrektur blieb der Button im Test
deaktiviert, nach der Korrektur kann das unveränderte Bild übernommen werden.

Das Manifest markiert zusätzlich `android.hardware.camera` (Rückkamera) und
`android.hardware.camera.autofocus` als optional. Zusammen mit `camera.any` und
`camera.front` sind damit alle vier Kamera-Merkmale ausdrücklich nicht zwingend.
Das überschreibt auch die durch die Kameraberechtigung implizierten
[Google-Play-Hardwareanforderungen](https://developer.android.com/guide/topics/manifest/uses-feature-element#permissions).
Die Feature-Liste des gebauten Release-APK enthält alle vier als
`uses-feature-not-required` und keinen erforderlichen Kameraeintrag mehr.

120 Unit-/Widget-Tests, Analyse und Format-/Diff-Prüfung erfolgreich. Der native
Kameratest mit Unterbrechung, Wiederöffnung, Aufnahme und Abbruch ist ebenfalls
erfolgreich. Die Effektrezepte und die neun Spielabläufe sind unverändert und
wurden für diese beiden Review-Korrekturen nicht nochmals nativ durchlaufen.

Aktualisierte normale Release-APK nach den Review-Korrekturen: 89.731.190 Byte;
SHA256: `97BAF069C5EE8ED4E40FE99CC5D05CBA5ED6787490523FAD471238EFEFBDE0B2`.
Kaltstart, Fensterschutz und geprüfte Prozesslogs erfolgreich; Remote-CI und
echtes TalkBack bleiben als getrennte Prüfungen ausgewiesen.
