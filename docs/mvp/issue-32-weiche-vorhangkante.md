# Großflächige Aufdeckansicht

Die Übergabeansicht nutzt die verfügbare Höhe als zusammenhängenden Vorhang.
Avatar-Platzhalter, Spielerüberschrift und die kurze Aufforderung „Du bist dran“
bewegen sich gemeinsam. Die untere Kante ist geschwungen, mit Schatten und einem
limettenfarbenen Griff samt Aufwärtspfeilen. Der Platzhalter bereitet spätere
Avatare vor; Bilderfassung und Speicherung gehören nicht zu dieser Umsetzung.

## Layout und Bedienung

- Die Phasenanzeige und „Gruppe bearbeiten“ bleiben außerhalb der Abdeckung.
  Der Übergabebutton bewegt sich unter dem Spielernamen mit dem Vorhang.
  Die gesamte Ansicht liegt innerhalb der Android-Systemleisten. Auf kurzen
  Ansichten bleibt eine Mindesthöhe für den Vorhang erhalten; bei Bedarf lässt
  sich die Seite scrollen. Die Button-Touchfläche wird nicht mit dem Avatar skaliert.
- Das Geheimnis liegt fest unten auf einer violetten Fläche. Lange Inhalte
  brechen um und werden bei Platzmangel proportional verkleinert. Ein eigener
  Ausschnitt gibt den Inhalt während der Teilöffnung schrittweise frei.
- Die ganze Abdeckung ist greifbar, auch über Avatar, Namen und Übergabebutton.
  Ein Pixel Fingerweg bewegt den Vorhang um ein Pixel. Der Anschlag legt nur die
  untere Lesefläche frei; er liegt deutlich unter dem oberen Bildschirmrand.
  Der Weg wächst mit der Schrift und ist auf kurzen Flächen begrenzt. Beide Rollen
  verwenden dieselbe Geometrie. Anhalten, Zurückziehen und erneutes Ansehen
  funktionieren ohne Schwung oder Einrasten.
- Der große violette Avatar-Kreis, der reine Spielername, die mittige Übergabe
  und die breite, symmetrisch gebogene Unterkante prägen die Gestaltung.
- Ein Tippen auf den freigegebenen Übergabebutton bleibt eine eigene Aktion.
  Verliert der noch nicht begonnene Drag gegen diesen Tap, verdeckt er nicht
  vorher die Runde und entwertet dadurch nicht den Übergabe-Callback.
- Loslassen und Gestenabbruch entfernen die privaten Inhalte sofort; nur die
  leere Abdeckung gleitet zurück. Bei reduzierter Bewegung schließt sie sofort.
- „Weiter“ wird nach dem ersten vollständigen Ansehen freigegeben. Jede Übergabe
  beginnt verdeckt, die letzte führt zur bestehenden Bereit-Phase.

## Schutz und Zugänglichkeit

Die Rundenlogik und Android-Screenshotsperre bleiben bestehen. Unterbrechungen,
Dialoge und Rücknavigation verbergen sofort und entwerten alte Pointer-Ereignisse.
Geschlossene und teilweise sichtbare Geheimnisse fehlen im Semantikbaum. Erst
bei vollständiger Öffnung wird die private Live-Region zugänglich.
Spielerüberschrift und Screenreader-Aktion haben getrennte Semantikknoten.
Screenreader sowie Enter/Leertaste erlauben weiterhin acht Sekunden Ansehen.

## Prüfung

Die Widget-Tests sichern beide Rollen, feste Textposition, Teilöffnung und
Zurückziehen, gemeinsame Bewegung des Avatar-Bereichs, Gestenabbruch,
Unterbrechungen, alte Ereignisse, sichere Übergaben und den zeitlich begrenzten
barrierefreien Zugriff ab. Ein zusätzlicher Test kombiniert 320 × 568,
200 Prozent Schrift, Systemleisten, lange Namen/Geheimnisse und reduzierte
Bewegung. Die vorhandenen Prüfungen für Kontrast und Touchflächen bleiben aktiv.

Die Android-Ablauftests verwenden echte Inhalte und die Produktionsuhr. Sie
prüfen beide Gewinner, Folgerunden und Verlassen mit verdeckten Übergaben.
Echtes TalkBack und die Bedienung auf einem physischen Handy bleiben offene
Praxistests.

Lokale Abnahme am 31.10.2026: alle 76 Unit-/Widget-Tests, Analyse, Format- und
Diff-Prüfung erfolgreich. Die drei Android-Abläufe bestanden mit der endgültigen
Fassung auf API 36.1 bei 320 × 568 und 200 Prozent Schrift. Zuvor bestanden sie
auch bei normaler Anzeige. Roboto-Sichtprüfung beider Rollen einschließlich
Teilöffnung, 320 × 568, 200 Prozent Schrift und Systemleisten durchgeführt.

Nachbesserung nach Bedienfeedback: Ganze Abdeckung statt nur Griff greifbar,
verkürzter Öffnungsweg und überarbeitete Spieleransicht. Ein weiterer Widget-Test
prüft beide Rollen mit Start auf Avatar, Name, Hintergrund und Übergabebutton;
er sichert dabei 1:1-Bewegung, kurzen Anschlag und ausbleibenden Personenwechsel
beim Ziehen ab. Android-Tests wechseln ebenfalls zwischen Startflächen und prüfen
den kurzen Weg. Alle 77 Unit-/Widget-Tests, Analyse und Sichtprüfung bestanden.

Auch alle drei aktualisierten Android-Abläufe bestanden auf API 36.1 bei
320 × 568 und 200 Prozent Schrift. Die Testhilfe bringt die tatsächliche
Startfläche vor dem Ziehen ins Bild; der Griff allein reicht dafür auf einer
scrollenden kleinen Ansicht nicht aus.
