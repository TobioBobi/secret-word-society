# Rundendauer vor dem Start anpassen

## Verhalten

Ohne manuelle Auswahl gelten seit Issue #78 15 Sekunden pro Person. In der
Bereit-Ansicht nach der Kartenverteilung direkt vor dem Timerstart lässt sich die
Dauer über Minus/Plus in Schritten von 15 Sekunden ändern. Erlaubt sind
00:30 bis 15:00; am jeweiligen Ende ist der passende Button deaktiviert.
Die gewählte Dauer und der Startbutton zeigen denselben Wert.
Seit Issue #72 ist dies in Erst- und Folgerunden der einzige Einstellort.
Die Gruppenansicht zeigt weder einen Zeitregler noch eine Dauer in ihrer Zusammenfassung.

Eine manuelle Dauer bleibt in der laufenden Sitzung für Folgerunden und beim
Bearbeiten der Gruppe erhalten. Es gibt keinen „Automatisch“-Button.
Es gibt keine Speicherung über App-Neustarts hinweg.
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
auf 320 × 568 bei 200 Prozent Schrift, beide Grenzen, manuelle Folgerunden und das
Plattformsignal bei Ablauf im Vordergrund bzw. später Rückkehr.

Der Android-Test „manual timer: real 30-second expiry and retained follow-up“
ändert die Zeit nach der Kartenverteilung, wartet echte 30 Sekunden bis
zur Abstimmung und prüft die Übernahme in die Folgerunde samt erneuter
Anpassung. Er verwendet den gebündelten Katalog
und die Produktionsuhr.

Echtes TalkBack und ein physischer Handytest bleiben gesonderte Praxisprüfungen.

Die ursprüngliche Umsetzung von Issue #30 wurde lokal auf Android API 36.1 bei
320 × 568 und 200 Prozent Schrift mit Produktionsuhr und gebündeltem Katalog
geprüft. Der für Issue #72 angepasste Android-Ablauf wurde lokal noch nicht erneut ausgeführt.
Die visuelle Prüfung mit Roboto umfasst Gruppen- und Bereit-Ansicht auf
390 × 844 sowie 320 × 568 bei 200 Prozent Schrift. Flutter-Analyse,
Formatprüfung und die Unit-/Widget-Suite sind Teil der Abschlussprüfung.
