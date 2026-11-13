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

## Gruppenvorbereitung (#86)

Die Gruppenansicht verwendet `CutoutSurface` für Personen und Imposter-Anzahl.
Namen erhalten eine eigene breite Zeile; Avatar und Fotoaktionen stehen darunter
und können umbrechen. Die Sliver-Liste bleibt auch für vierzehn Personen scrollbar.
Der gemeinsame `PlayerAvatarView` setzt einen Papier-Rahmen um den bisherigen
Bildinhalt, ohne Saatwert, Foto, Zuschnitt oder optionale Effekte zu verändern.

`buildGroupCutoutTheme` begrenzt Eingabe-, Symbol- und Dialoggestaltung auf die
Vorbereitung. `PaperInputBorder` übernimmt die gemeinsame Papierkontur und lässt
die Lücke für schwebende Beschriftungen sowie native Fokus-/Fehlerzustände frei.
Der Umbenennen-Dialog bekommt dasselbe Theme auch auf seiner eigenen Route.
Titel, Eingabe und Aktionen scrollen dort gemeinsam, damit eine eingeblendete
Tastatur bei großer Schrift dem Eingabefeld nicht den Platz nimmt. Die native
Dialogbezeichnung und die Überschriftensemantik bleiben erhalten.
Die Hauptaktion verwendet `CutoutAction`, einschließlich deaktiviertem Start
und Ladezustand. Der Zustandscontroller kennt den initial deaktivierten Zustand
bereits vor dem Aufbau des nativen Buttons.

Die Regeln für Gruppengröße, Namen, Imposter-Anzahl, Sitzung und Rundenstart
bleiben unverändert. Aufnahme und Bearbeitung selbst folgen im Foto-Teilticket.

## Geheimnisse und Übergabe (#87)

Der Vorhang verwendet eine flache auberginefarbene Papierfläche mit kantiger
Unterkante und violetter Papierlage. Diese Lage bleibt innerhalb der Maske,
damit sie keinen zusätzlichen Geheimnistext verdeckt. Dieselbe Kantenlinie
bestimmt die sichtbare Texthälfte für die bestehende Weitergabefreigabe.
Anschlag, Gesten, Vorhanghinweis und Übergabeanimationen bleiben erhalten.

Identität und Fortschritt übernehmen die Papierkontur. Der Avatar-/Fotorahmen
behält den Bildinhalt und bewegt sich weiterhin mit dem Vorhang. Wort und
Imposter-Hinweis stehen auf einer hellen Papierkarte mit dunkler Schrift und
versetztem violettem Schatten. Der Messschlüssel bleibt am Geheimnistext,
unabhängig von Kartenpolsterung und Rollenbezeichnung.
Lange Einzelwörter werden mit den tatsächlichen Schriftmetriken in die verfügbare
Zeile eingepasst; mehrteilige Geheimnisse dürfen zwischen Wörtern umbrechen.
Das verhindert einzelne abgetrennte Endbuchstaben bei großer Systemschrift.
Die Ausgangsbreite bleibt auf den verfügbaren Platz begrenzt. Vergrößerte
Systemschrift bleibt erhalten, wenn die Inhalte passen; die gesamte Karte wird
nur bei tatsächlichem Überlauf verkleinert.

Die zugängliche Weitergabe bleibt ein nativer Button mit Papierkontur,
deaktiviertem Zustand und eigener Fokuslinie. Öffentliche und private Semantik,
zeitbegrenztes Aufdecken, Unterbrechungsverdeckung und reduzierte Bewegung
behalten ihre bisherigen Regeln.

## Rundendauer, Diskussion und Zeitablauf (#88)

Bereit-Karte, Dauerauswahl, Timer und Zeitablauf verwenden `CutoutSurface`
aus der gemeinsamen Grundlage. Farbe, Schriftfarbe und Schattenfarbe lassen
sich passend zur Papierlage wählen; die Gruppenansicht behält ihre bisherigen
Standardwerte. Timerziffern behalten tabellarische Zahlen und passen sich nur
bei Platzmangel in die verfügbare Breite ein. Ihre Semantik bleibt erkundbar,
ohne jede Sekunde eine Ansage auszulösen.

Start und Überspringen verwenden `CutoutAction`, die Dauerschritte native
Symbolbuttons mit Papierkontur und Fokuslinie. Die bestehende Anzeige und
deaktivierte Semantik an den Dauergrenzen bleiben erhalten. Die Bestätigung
zum Überspringen erhält ebenfalls eine Papierkontur. Überschrift und beide
Aktionen scrollen gemeinsam, damit sie auch bei großer Systemschrift erreichbar
bleiben. Dialogbezeichnung, Überschriftensemantik und native Buttonrollen
bleiben erhalten.

Dauerregeln, manuelle Auswahl, Zurück-Verhalten, Deadline und Phasenwechsel
bleiben unverändert. Der Zeitablauf behält seine endliche Bewegung und wird
bei reduzierter Bewegung weiterhin sofort als ruhige Karte angezeigt.
