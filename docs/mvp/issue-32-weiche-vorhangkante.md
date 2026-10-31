# Großflächige Aufdeckansicht

Die Übergabeansicht nutzt die verfügbare Höhe als zusammenhängenden Vorhang.
Avatar-Platzhalter, Spielerüberschrift und die kurze Aufforderung „Du bist dran“
bewegen sich gemeinsam. Die untere Kante ist geschwungen, mit Schatten und einem
limettenfarbenen Griff samt Aufwärtspfeilen. Der Platzhalter bereitet spätere
Avatare vor; Bilderfassung und Speicherung gehören nicht zu dieser Umsetzung.

## Layout und Bedienung

- Die Phasenanzeige und die getrennten Aktionen bleiben außerhalb der Abdeckung.
  Die gesamte Ansicht liegt innerhalb der Android-Systemleisten. Auf kurzen
  Ansichten bleibt eine Mindesthöhe für den Vorhang erhalten; bei Bedarf lässt
  sich die Seite scrollen. Die Gruppenaktion nutzt eine kompaktere Schrift.
- Das Geheimnis liegt fest unten auf einer violetten Fläche. Lange Inhalte
  brechen um und werden bei Platzmangel proportional verkleinert. Ein eigener
  Ausschnitt gibt den Inhalt während der Teilöffnung schrittweise frei.
- Ein Pixel Fingerweg bewegt den Vorhang um ein Pixel. Der Griff bleibt am oberen
  Anschlag innerhalb der Fläche. Anhalten, Zurückziehen und erneutes Ansehen
  funktionieren ohne Schwung oder Einrasten.
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
