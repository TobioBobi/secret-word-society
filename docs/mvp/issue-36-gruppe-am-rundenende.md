# Gruppe am Rundenende bearbeiten

Auf dem Ergebnisbildschirm steht bei beiden Rundenausgängen unter
„Noch eine Runde“ die Aktion „Gruppe bearbeiten“. Sie öffnet die bestehende
Gruppe ohne Verlassensdialog. Während einer laufenden Runde bleibt diese
Aktion ausgeblendet.

Die vorhandene Gruppenbearbeitung erlaubt Hinzufügen, Entfernen, Umbenennen
und Avatarwechsel. Unveränderte Personen behalten ihre Identität und ihren
Avatar; auch Umbenennen erhält beides. Die Mindestspielerzahl gilt weiter.
Die nächste Runde verwendet die bearbeitete Gruppe und den bestehenden
Wortvorrat. Der direkte Folgerundenstart bleibt erhalten.

Zusätzliche Spieleinstellungen werden durch dieses Issue nicht eingeführt.
Der Umbenennen-Dialog hat scrollbar angeordneten Inhalt, damit Namenseingabe
und Aktionen auch bei kleiner Anzeige, großer Schrift und Tastatur erreichbar
bleiben. Alte Ergebnisaktionen können keine neue Runde verwerfen.

## Prüfungen

- Widget-Abläufe für beide Siegergebnisse bei 320 × 568 und 200 Prozent
  Schrift: Bearbeitung öffnen, umbenennen mit Tastaturbereich, Avatar erhalten,
  entfernen, Mindestspielerzahl prüfen, hinzufügen und neu starten.
- Bestehende Tests für direkten Folgerundenstart, Geheimnisschutz und
  Android-Touchflächen bleiben erhalten.
- Android-Ablauf mit echten Assets und Produktionsuhr: nach Gruppensieg
  umbenennen, entfernen und hinzufügen; nach Imposter-Sieg direkt neu starten.
  Beide Wege erhalten den Avatar der unveränderten ersten Person.
- Sichtprüfung mit Roboto bei normaler Anzeige und 320 × 568 / 200 Prozent.

Physisches Gerät und echtes TalkBack bleiben als Praxistests offen.
