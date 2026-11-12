# Cutout-Grundlage

Die Startseite verwendet die in #84 bestätigte Bildsprache. Das vorhandene,
freigestellte Logo und sämtliche Texte und Ziele bleiben erhalten.
Die übrigen Ansichten werden in den Folgetickets umgestellt.

## Wiederverwendung

- `PartyColors` ist die gemeinsame Palette: Aubergine, Limette, Violett,
  helle Schrift und ein dunkler violetter Papierschatten. Die semantischen
  Farben im bestehenden Material-Theme bleiben für Zwischenstände nutzbar.
- `PartyTypography.heading` und `.action` definieren kräftige, gerade
  Überschriften und kurze Aktionen. Fließtext, Namen und Zahlen behalten
  die gut lesbare Systemschrift des Themes. Keine Schrift wird nachgeladen.
- `PaperBorder` zeichnet dieselbe leicht unregelmäßige, kantige Kontur für
  gefüllte und umrandete Flächen. Sie ist als `OutlinedBorder` für Material,
  ShapeDecoration, Karten, Dialoge, Symbolaktionen und Auswahlflächen nutzbar.
  Eingabefelder können dieselbe Kontur über eine passende InputBorder-Adaption
  erhalten, sobald ihre Ansichten umgestellt werden.
- `Cutout.padding`, `.gap` und `.shadowOffset` legen sichere Textabstände,
  Gruppierung und die flache Schattenlage fest. Inhalte bestimmen die Höhe;
  Papierflächen haben keine festen Textabmessungen.
- `CutoutAction` bietet Haupt-, Neben- und umrandete Aktionen auf nativen
  Material-Buttons. Fokus hat eine kontrastierende Kontur, Druck eine
  Zustandsüberlagerung und ein sofortiges Absinken auf den Schatten;
  reduzierte Bewegung unterdrückt die Verschiebung. Deaktivierte Aktionen
  behalten native deaktivierte Semantik und reagieren nicht auf Eingaben.
- `PaperConfetti` ist rein dekorativ und aus der Semantik ausgeschlossen.

Diese Bausteine werden schrittweise in den Spielansichten angewendet.
Phasenkennzeichnung, Auswahl, Mengen-/Dauerauswahl und Statusmeldungen können
die Papierkontur und Tokens übernehmen; ihre fachlichen Zustände und
Semantik bleiben in den jeweiligen Komponenten. Noch unbenötigte Varianten
oder ein separater Showroom werden nicht vorab eingeführt.

## Prüfung

`test/start_screen_test.dart` prüft Navigation, Sitzung und Namensentwurf,
Einstellungen/Datenschutz, die Anleitung, Druck/Abbruch, reduzierte Bewegung
sowie Tastaturfokus, Aktivierung und Button-Semantik bei 320 × 568 mit
200 Prozent Schrift. Zusätzliche Render- und Android-Prüfungen kontrollieren
Logo, Papierlagen, Textumbrüche, Scrollen und erreichbare Aktionen.
Physisches Gerät und tatsächliche TalkBack-Ausgabe bleiben gesonderte Abnahmen.
