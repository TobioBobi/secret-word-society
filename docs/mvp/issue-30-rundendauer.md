# Rundendauer vor dem Start anpassen

## Verhalten

Ohne manuelle Auswahl gelten weiterhin 30 Sekunden pro Person. In der
Gruppenansicht und auf der Bereit-Ansicht vor dem Timerstart lässt sich die
Dauer über Minus/Plus in Schritten von 30 Sekunden ändern. Erlaubt sind
00:30 bis 15:00; am jeweiligen Ende ist der passende Button deaktiviert.
Die gewählte Dauer und der Startbutton zeigen denselben Wert.

Eine manuelle Dauer bleibt in der laufenden Sitzung für Folgerunden und beim
Bearbeiten der Gruppe erhalten. „Automatisch“ stellt die Berechnung nach
Gruppengröße wieder her. Es gibt keine Speicherung über App-Neustarts hinweg.
Die Rollenstaffelung hängt weiterhin ausschließlich von der Personenzahl ab.

Nach dem Timerstart sind keine Anpassungen möglich. Jede Runde hält ihre
eigene Dauer unveränderlich fest; Zustandswechsel erhalten sie. Die Deadline
entsteht erst beim bewussten Start der Diskussion. Ablauf, Unterbrechungen,
Rundensignal und Enthüllungs-Countdown verwenden ihre bisherigen Abläufe.

## Technische Umsetzung

- `RoundRules` definiert Schrittweite, Grenzen und Validierung.
- `GameSession` hält die optionale manuelle Auswahl; `null` bedeutet automatisch.
- `GameRound` erhält die konkrete Dauer vor dem Ziehen eines Wortes. Änderungen
  sind nur in der Bereit-Phase möglich; Folgerunden übernehmen die Dauer.
- Die Oberfläche zeigt bei großer Schrift die Zeit über den Plus-/Minusbuttons.
  Alle Aktionen bleiben scrollbar und haben benannte Touchflächen.

## Prüfungen

`test/game/manual_duration_test.dart` prüft dynamische Standardwerte,
Gruppenänderung, Rückkehr zur Automatik, Grenzen, ungültige Werte, feste
Deadline, Unterbrechung und Folgerunde. Die Widget-Tests prüfen die Bedienung
auf 320 × 568 bei 200 Prozent Schrift, beide Grenzen, Rücksetzen und das
Plattformsignal bei Ablauf im Vordergrund bzw. später Rückkehr.

Der Android-Test „manual timer: real 30-second expiry and retained follow-up“
ändert die Zeit bereits vor der Kartenverteilung, wartet echte 30 Sekunden bis
zur Abstimmung und prüft die Übernahme in die Folgerunde samt erneuter
Anpassung und Rückkehr zur Automatik. Er verwendet den gebündelten Katalog
und die Produktionsuhr.

Echtes TalkBack und ein physischer Handytest bleiben gesonderte Praxisprüfungen.

Lokal auf Android API 36.1 bei 320 × 568 und 200 Prozent Schrift erfolgreich
geprüft: der neue Ablauf mit Produktionsuhr und gebündeltem Katalog.
Die visuelle Prüfung mit Roboto umfasst Gruppen- und Bereit-Ansicht auf
390 × 844 sowie 320 × 568 bei 200 Prozent Schrift. Flutter-Analyse,
Formatprüfung und die Unit-/Widget-Suite sind Teil der Abschlussprüfung.
