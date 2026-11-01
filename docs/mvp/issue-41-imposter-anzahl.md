# Imposter-Anzahl vor der Rollenverteilung

In der Gruppenansicht führt Minus/Plus durch jede feste Zahl und jeden
benachbarten Zweierbereich: 1, 1–2, 2, 2–3 bis Spielerzahl minus eins. Die Buttons
sind an den Grenzen deaktiviert. Mindestens eine Person bleibt immer Nicht-Imposter.
Vor der ersten manuellen Wahl gilt weiterhin die automatische Staffel aus #25.
Es gibt keinen Automatisch-Button und keine dauerhafte Speicherung.

Die manuelle Zahl oder der Bereich bleibt bei Folgerunden und Gruppenbearbeitung
erhalten. Überschreitet die Wahl nach einer Gruppenänderung Spielerzahl minus eins, reduziert sich die Wahl
sofort auf Spielerzahl minus eins als feste Zahl; der Auswahlwert zeigt dies an.
Um die Rollenanzahl für eine Folgerunde zu ändern, „Gruppe bearbeiten“ wählen.
Bereits verteilte Rollen werden niemals nachträglich geändert.

`ImposterChoice` beschreibt ausschließlich die öffentliche Konfiguration.
Die Runde zieht bei einem Bereich mit `nextInt(2)` erneut eine der beiden
gleich wahrscheinlichen Anzahlen. Eine partielle Fisher–Yates-Ziehung verteilt
Rollen eindeutig auf zufällige Personen. Die privaten Zuweisungen bleiben im
Rundenmodell verborgen. Bereit-, Timer- und Abstimmungsansicht zeigen nur die
öffentliche Zahl bzw. den Bereich, auch im Semantikbaum.

Die vorhandenen Hinweise werden gemischt und zyklisch verteilt. Dadurch wird
jeder Hinweis vor seiner ersten Wiederholung vergeben; die Häufigkeiten
unterscheiden sich höchstens um eins. Der Katalog braucht keine neuen Hinweise.

Das öffentliche Maximum bestimmt die Abstimmungsgrenze unabhängig vom geheimen
Ziehergebnis. Nur genau alle Imposter ohne Unschuldige bedeuten Gruppensieg.
Mindestens eine Person kennt immer das Wort. Countdown, Unterbrechungsschutz und
verdeckte Übergaben bleiben erhalten.

## Prüfungen

- Modelltests für alle Gruppengrößen 3–14 und alle festen Zahlen/Bereiche:
  eindeutige Rollen, erlaubte Ziehergebnisse, gleichmäßige Hinweise, exakte
  Gewinnerbestimmung, öffentliche Abstimmungsgrenze und neue Runde.
- Gezielter Zufallstest für die beiden gleich wahrscheinlichen Bereichswerte.
- Sitzungstests für Standard, manuelle Speicherung, Gruppenverkleinerung,
  ungültige Eingaben, Schutz laufender Runden und neue App-Sitzung.
- Widget-Ablauf auf 320 × 568 mit 200 Prozent Schrift, beschrifteten
  Android-Touchflächen, Semantik, allen Auswahlschritten und Gruppensieg bei
  maximal erlaubter Imposter-Anzahl. Bestehende Geheimnis-/Lifecycle-Tests laufen weiter.
- Zwei Android-Abläufe mit echtem Offline-Katalog: sechs Personen mit 4–5 bzw.
  fünf Impostern, Hinweise mehrfach verteilen, exakt abstimmen, Folgerunde und
  Reduktion der Gruppe auf drei. Die injizierte Uhr beschleunigt die Diskussion.

Echtes TalkBack, die Bedienung auf einem physischen Handy und die Spielbalance
ungewöhnlicher Rollenverteilungen bleiben Praxisprüfungen.
