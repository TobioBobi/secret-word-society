# Ticket 18: Countdown vor der Enthüllung

Nach dem Bestätigen des mündlichen Abstimmungsergebnisses zeigt eine eigene
Spielphase drei Sekunden lang „3, 2, 1“. Erst danach werden Gewinner, Imposter
und geheimes Wort freigegeben. Die Auswahl ist währenddessen abgeschlossen;
erneutes Bestätigen oder alte Aktionen können den Countdown nicht neu starten.

Die drei Sekunden und ihre Darstellung sind eine Arbeitsentscheidung für die
beauftragte Umsetzung. Der separate Rundentimer bleibt vorübergehend bei zehn
Sekunden; seine Rückstellung gehört zu Ticket 19.

## Unterbrechungen und Bedienung

- App-Wechsel, Sperren und der Verlassensdialog pausieren die genaue Restzeit.
  Die Enthüllung wartet auf die Rückkehr zur sichtbaren Runde.
- „Weiterspielen“ setzt den Countdown fort. „Runde verlassen“ verwirft ihn und
  behält die Gruppe. System-Zurück verwendet denselben Dialog.
- Nach Ablauf folgt genau eine Auflösung. Jede neue Runde beginnt mit verdeckten
  Karten und erhält nach ihrer Abstimmung wieder einen vollständigen Countdown.
- Screenreader erhalten während des Countdowns ausschließlich dessen neutrale
  Texte und die verbleibenden Sekunden als Live-Region. Ergebnis-Widgets sind
  bis zum Ablauf nicht im Widget- oder Semantikbaum enthalten.
- Große Ziffern im bestehenden Party-Look, ohne zusätzliche Animation oder Ton.
  Bei wenig Höhe oder großer Schrift entfällt der zusätzliche Kopfbereich,
  damit die Countdown-Zahl auch auf 320 × 568 bei 200 % Schrift sichtbar bleibt.

## Validierung

- Modelltests: Freigabe exakt an der Frist, keine vorzeitige Auflösung,
  unveränderliche Auswahl, Restzeit auf Millisekunden, wiederholtes Pausieren
  und Fortsetzen sowie frischer Zustand in Folgerunden.
- Widget-Tests: „3, 2, 1“ bei beiden Gewinnern und in Folgerunden, Doppeltippen,
  alte Aktionen, App-Unterbrechungen, Zurück/Dialog mit langer Wartezeit,
  Abbruch, Dispose und Schutz der Semantikausgabe.
- Layout-/Accessibility-Tests: Android-Touchflächen, Textkontrast, beschriftete
  Aktionen und vollständig sichtbare Countdown-Zahl bei normaler und 200-%-Schrift.
- Android-Integration: Beide Gewinner mit echten Assets und Produktionsuhr;
  Geheimnisse bleiben vor Ablauf verborgen, danach Auflösung und neue Runde.
  Der bestehende dritte Test prüft Kartenverbergen, Abbruch und Neustart.

Lokale Prüfprotokolle und gerenderte Ansichten liegen ignoriert unter
`build/qa/ticket18*`. Physisches Handy, echter TalkBack und Herstellerverhalten
bleiben gesonderte Praxisprüfungen. Die Integrationstests simulieren keine
nativen App-Wechsel; diese Zustandswechsel prüfen die Widget-Tests.

Lokaler Stand am 25.10.2026: Alle 58 Unit-/Widget-Tests, Flutter-Analyse,
Format- und Diff-Prüfung erfolgreich. Countdown mit Roboto bei normaler und
200-%-Schrift visuell geprüft; Ziffer und Gruppenaktion bleiben auch auf
320 × 568 sichtbar. Drei Android-Integrationstests auf API 36.1 mit echten
Assets und Produktionsuhr bestanden, nach der Layoutverfeinerung auch auf dem
endgültigen Stand erneut erfolgreich (65 Sekunden Testausführung, zusätzlich
35 Sekunden Debug-Build und drei Sekunden Installation).
