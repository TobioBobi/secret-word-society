# Issue #34: Cutouts-Avatare

Jede neue Person erhaelt automatisch einen lokal generierten Cutouts-Avatar.
Der Wuerfel unter dem Gesicht in der Gruppe ersetzt ihn direkt und beliebig oft.
Antippen des Namens oeffnet die Namensaenderung; ID und Avatar bleiben erhalten.
Die Gruppe lebt weiterhin nur in der laufenden Sitzung.

## Umsetzung

- `PlayerAvatar` haelt den zufaelligen Seed; der Stil ist fest `cutouts`.
  Die Zufallsquelle ist unabhaengig von Wort- und Rollenauswahl.
- `GameSession` ersetzt beim Wuerfeln oder Umbenennen nur die betroffene Person;
  Aenderungen sind waehrend einer Runde gesperrt. Folgerunden behalten die Personen.
- Eine gemeinsame SVG-Komponente zeigt dasselbe Gesicht in Gruppe, Vorhang,
  Abstimmung sowie bei Verdacht und Imposter im Ergebnis. Nur Namen dienen als
  semantische Identifikation; Bilder sind dekorativ und enthalten keine Rolle.
- Stil und Engine sind auf 10.6.0 beziehungsweise 10.7.0 festgesetzt.
  Es wird nur die Cutouts-Definition importiert. SVGs werden pro Avatar schwach
  zwischengespeichert, damit alte Sitzungen und verworfene Gesichter freikommen.
- Keine Netzwerk-, Kamera- oder Medienberechtigung hinzugefuegt.
  Quellen und Lizenzen: [Avatar-Hinweise](../avatar-credits.md).

## Pruefung

- 87 Unit-/Widget-Tests erfolgreich, einschliesslich reproduzierbarer SVGs,
  ID-Erhalt beim Umbenennen, Neuwuerfeln, Gruppenrueckkehr und Folgerunden.
- Touchflaechen und Screenreader-Beschriftungen fuer den Wuerfel bei normaler
  und 200 Prozent Schrift geprueft; bestehende Phasen-/Kontrasttests bestehen.
- Roboto-Sichtpruefung von Gruppe, grossem Vorhang und Ergebnis; kleine Displays
  bleiben scrollbar.
- Alle vier Android-Spielablaeufe auf API 36.1 bei 320 x 568 und 200 Prozent
  Schrift erfolgreich: zweimal neu wuerfeln, beide Gewinner, identischer Avatar
  in der Folgerunde, ungesehene Karten ueberspringen und Gruppenrueckkehr.
- Release-APK: 54.350.275 Byte gegenueber 49.871.352 Byte vor den Avataren:
  +4.478.923 Byte (+8,98 Prozent), universelle APK fuer mehrere Architekturen.
  Lizenzbundle fuer Engine/SVG und zusaetzlicher Cutouts-Hinweis vorhanden;
  keine weiteren Avatar-Assets. Installiert und kalt gestartet. Release-Manifest
  ohne Internet-, Kamera- oder Medienberechtigungen; Offline-Pfad damit auch
  im ausgelieferten Paket abgesichert.
- Echtes TalkBack und Bedienung am physischen Handy bleiben Praxistests.
