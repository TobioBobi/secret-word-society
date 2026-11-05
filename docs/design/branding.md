# Markenassets (Issue #24)

Verbindliche Gestaltung: [Issue #24](https://github.com/TobioBobi/secret-word-society/issues/24)
und `issue-24-approved-brand-concept.png`.

## Dateien

- `assets/branding/psst-source.png`: transparenter Rastermaster der festen
  Psst-Markenfigur, 1254 × 1254 Pixel. Keine Zufallsavatare.
- `assets/branding/app-icon.png`: quadratisches Icon mit cremefarbenem
  Hintergrund, 512 × 512 Pixel, ohne vorgezeichnete Android-Maske.
- `assets/branding/start-logo.png`: freigestellte Dreiergruppe mit dreizeiligem
  Schriftzug, 2095 × 751 Pixel. Für dunklen Hintergrund (z. B. `#1B1027`).
  In Flutter bereits als Asset registriert; die Startseite folgt separat in #39.
  Bei späterer Verwendung den gesamten Schriftzug für Screenreader einmal als
  „Secret Word Society“ beschriften, etwa über `Image.asset(..., semanticLabel:
  'Secret Word Society')`.

## Android

`dart run tool/generate_brand_icons.dart` erzeugt aus dem Rastermaster die fünf
Legacy-Dichten, das 512-Pixel-Icon und den transparenten adaptiven Vordergrund.
Es verwendet die bestehende Dart-Abhängigkeit `image` und benötigt keinen
zusätzlichen Assetgenerator. Nach Änderungen die Dateien neu erzeugen.

Ab API 26 kombiniert `mipmap-anydpi-v26/ic_launcher.xml` den Vordergrund mit
`@color/ic_launcher_background` (`#FFF0DB`). Das Motiv liegt in der zentralen
66/108-Schutzzone, die äußeren Flächen bleiben transparent. Launcher bestimmen
die Maske. Es gibt keine gesonderte monochrome Variante.
Siehe [Android: Adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).

## Erstellung

Die beiden Rastermaster wurden mit dem eingebauten Imagegen-Werkzeug aus der
bestätigten Bildtafel abgeleitet. Vorgaben für das Icon: nur die lilafarbene
Psst-Figur samt violetten/limettenfarbenen Akzenten, unveränderte Bildsprache,
transparenter Hintergrund, keine Schrift oder Kachel und ausreichend Rand.
Vorgaben für das Logo: kompakte horizontale Anordnung der drei bestätigten
Figuren links und `SECRET / WORD / SOCIETY` rechts, cremefarbene erste/dritte
Zeile, limettengrüne zweite Zeile, echter transparenter Hintergrund, keine
Präsentationsüberschriften oder cremefarbene Kachel. Die Figuren behalten
skeptischen, nervösen beziehungsweise selbstsicher-frechen Ausdruck.

## Prüfung

Lokale Sichtprüfung: Kreis, abgerundete und eckige Maske; Icons mit 24, 32 und
48 Pixeln; Logo auf dunklem Hintergrund mit 900 und 300 Pixeln Breite.
Gesichter, Psst-Geste und Schriftzug bleiben erkennbar. Die Startseiten-
Navigation und deren Layout-/Screenreaderprüfung gehören zu #39.
