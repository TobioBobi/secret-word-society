# Cutout-Grundlage

Die App verwendet die in #84 bestätigte Bildsprache. Das vorhandene,
freigestellte Logo und sämtliche Texte und Ziele bleiben erhalten.
Die Umsetzung der Ansichten aus #85–#91 ist integriert. Prüfstand und gemeinsame
visuelle Abnahme stehen in [Cutout-Gesamtprüfung](cutout-acceptance.md).

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
  Eingabefelder verwenden dieselbe Kontur über `PaperInputBorder`.
- `Cutout.padding`, `.gap` und `.shadowOffset` legen sichere Textabstände,
  Gruppierung und die flache Schattenlage fest. Inhalte bestimmen die Höhe;
  Papierflächen haben keine festen Textabmessungen.
- `CutoutAction` bietet Haupt-, Neben- und umrandete Aktionen auf nativen
  Material-Buttons. Fokus hat eine kontrastierende Kontur, Druck eine
  Zustandsüberlagerung und ein sofortiges Absinken auf den Schatten;
  reduzierte Bewegung unterdrückt die Verschiebung. Deaktivierte Aktionen
  behalten native deaktivierte Semantik und reagieren nicht auf Eingaben.
- `PaperConfetti` ist rein dekorativ und aus der Semantik ausgeschlossen.

Diese Bausteine werden in den Spielansichten angewendet.
Phasenkennzeichnung, Auswahl, Mengen-/Dauerauswahl und Statusmeldungen verwenden
die Papierkontur und Tokens; ihre fachlichen Zustände und
Semantik bleiben in den jeweiligen Komponenten.

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


## Abstimmung und Auflösung (#89)

Verdächtige stehen auf kantigen Papierflächen mit versetzter violetter Lage.
Die ausgewählte Fläche ist limettengrün; zusätzlich zeigen die nativen Radio-
beziehungsweise Checkbox-Indikatoren die Auswahl. Die bisherigen Rollen,
Auswahlgrenzen und deaktivierten Zustände bleiben erhalten. Avatar und Name
können auf mehrere Zeilen umbrechen, damit lange Namen die verfügbare Breite
nutzen. Fotos und Avatare behalten ihren Inhalt.

Bestätigung und Folgerundenaktionen verwenden `CutoutAction`, Enthüllungszähler
und Ergebnis `CutoutSurface`. Die personenbezogene Bestätigung nutzt eine
kleinere Aktionsschrift, damit auch lange Namen bei großer Systemschrift
vollständig erreichbar bleiben. Die Systemvergrößerung wird beibehalten.
Der gemeinsame Verlassen-Dialog übernimmt die Papierkontur; Überschrift,
Beschreibung und Aktionen scrollen gemeinsam. Seine Nutzung in den vorherigen
Spielphasen behält dieselben Texte, Aktionen und Unterbrechungsregeln.

`test/voting_test.dart` prüft Radio-Semantik, Tastaturauswahl und Bestätigung
bis zur Folgerunde bei 320 × 568 mit 200 Prozent Schrift sowie lange Namen,
Ergebnis und die bestehenden Enthüllungs-/Unterbrechungsregeln.
`test/dynamic_round_widget_test.dart` prüft Mehrfachauswahl, Checkbox-Semantik,
Erreichbarkeit, deaktivierte zusätzliche Auswahl und Folgerunden mit bis zu
vierzehn Personen. Physische Geräte und tatsächliche TalkBack-Ausgabe bleiben
gesonderte Abnahmen.

## Eigene Fotos (#90)

Der Fotoeditor verwendet dieselben Papierflächen und Aktionen für Aufnahmehilfe,
Kameravorschau, Foto, Verarbeitung, Fehler und Wiederholen. Die Fotovorschau liegt
auf einem hellen Rahmen mit violettem Schatten; Bilddaten, Zuschnitt und vorhandene
optionale Effekte bleiben unverändert. Der gemeinsame Avatar-/Fotorahmen in Gruppe
und Spiel bleibt erhalten. Systemeigene Berechtigungsdialoge bleiben unverändert.

Titel, Vorschauen, Meldungen und Aktionen scrollen gemeinsam. Der vollständige
Titel bleibt auch mit langen Namen lesbar und als Routenname und Überschrift
ausgezeichnet. Alle Aktionen werden gemeinsam aufgebaut, damit die Tastatur auch
bei langem Titel und großer Schrift die zunächst außerhalb des Bildschirms
liegenden Buttons erreicht. Native Buttonrollen, deaktivierte Zustände, Fokus-
und Druckreaktionen stammen aus `CutoutAction`. Verarbeitung bleibt eine einzelne
Live-Ansage; Fehler verwenden zusätzlich zu ihrer Akzentfarbe ein Fehlersymbol
und die vorhandene konkrete Meldung. Dekorative Symbole erzeugen keine Ansagen.

## Anleitung und Nebenansichten (#91)

`CutoutPage` hält Rücknavigation in der Werkzeugleiste und lässt die vollständige
Routenüberschrift mit dem Inhalt scrollen. Überschriften behalten Header- und
Routensemantik; Inhalte und Aktionen sind auch außerhalb des sichtbaren Bereichs
für die Tastatur aufgebaut. Comic-Szenen, Sprech-/Rollenkarten und Datenschutz
verwenden `CutoutSurface`, Nebenaktionen die nativen Buttons aus `CutoutAction`.
Texte, Figuren, Beispiele und Sitzung bleiben erhalten.

Die Lizenzübersicht liest weiterhin `LicenseRegistry.licenses`, gruppiert nach
Paket und zeigt sämtliche Einträge einschließlich Absätzen und Einrückungen.
Sie erhält eigene Papierflächen statt der festen Titelzeilen von `LicensePage`,
die lange Paketnamen bei großer Schrift kürzen. Die bisherigen Anwendungshinweise,
Lizenzanzahlen, Paketaktionen und Rückwege bleiben erhalten. Lange Lizenzdetails
verwenden eine Sliver-Liste: Nur sichtbare Absätze werden ausgelegt, auch beim
rund 1 MB großen nativen Foto-Lizenztext. Die Überschrift scrollt weiter mit;
einzelne Papierabsätze erhalten weiterhin Einrückungen und zentrierte Titel.
Lade- und Fehlerzustände
liegen ebenfalls auf Papierflächen. Lizenzen werden nicht nachgeladen.

`test/side_screens_test.dart` sichert vollständige Titel, letzte Lizenzabsätze,
Tastaturfokus/-aktivierung, Buttonsemantik und Sitzungserhalt bei 320 × 568 und
200 Prozent Schrift ab. Die vorhandenen Startseitentests prüfen weiterhin alle
Comic-Szenen bis zum Ergebnis. Diese Gestaltung ersetzt weder die beobachtete
Erstspieler-Abnahme aus #17 noch die tatsächliche TalkBack-/Geräteabnahme.
