# Dynamische Rundendauer und geheime Imposter-Anzahl

Umsetzung von [Issue #25](https://github.com/TobioBobi/secret-word-society/issues/25),
einschließlich der Entfernung des Testtimers aus
[Issue #22](https://github.com/TobioBobi/secret-word-society/issues/22).

## Vereinbarte Regeln

- 3–14 Personen, 30 Sekunden pro Person: 01:30 bis 07:00 Minuten.
- 3–5 Personen: ein Imposter. 6–10: zufällig ein oder zwei. 11–14: zwei oder drei.
- Die gezogene Anzahl bleibt bis zur Auflösung geheim. Die Gruppe sieht nur
  den möglichen Bereich. Imposter erfahren nichts über andere Rollen.
- Jeder Imposter bekommt einen unterschiedlichen Hinweis zum gemeinsamen Wort.
  Jedes der 100 Offline-Wörter hat drei kurze Hinweise mit je ein bis zwei Wörtern.
- Nach mündlicher Abstimmung wird gemeinsam der gesamte Verdacht bestätigt.
  Nur exakt alle Imposter ohne unschuldige Personen ergeben einen Gruppensieg.
  Gleichstände werden mündlich geklärt. Kein schrittweises Ausscheiden.

Die beiden möglichen Anzahlen werden gleich wahrscheinlich gezogen; dies ist
eine Umsetzungsentscheidung. Die Gruppenobergrenze und alle obigen Spielregeln
wurden für dieses Issue ausdrücklich festgelegt. Keine verdeckte Einzelabstimmung
aus Issue #16 und keine zusätzliche Spielkonfiguration.

## Umsetzung

`RoundRules` hält Zeiten, Grenzen und Anzahlen zentral. Die Verteilung zieht
unterschiedliche Personen ohne Wiederholungsversuche und mischt die Hinweise
unabhängig von den Spielern. Die geheime Zuordnung bleibt privat im unveränderlichen
Rundenzustand. Nur die aktuelle Karte gibt ihren eigenen Hinweis frei; sämtliche
Imposter und der Gewinner sind erst nach dem bestehenden Enthüllungs-Countdown
zugänglich.

Ab sechs Personen bietet die Abstimmung Kontrollkästchen mit der öffentlich
bekannten maximal möglichen Imposter-Anzahl als Obergrenze: zwei bei 6–10,
drei bei 11–14 Personen. Ist die Grenze erreicht, sind weitere Personen
deaktiviert; ausgewählte Personen bleiben abwählbar. Nach dem Abwählen ist
ein Platz wieder frei. Auch der Spielkern ignoriert überzählige Auswahlen.
Die Grenze verrät nicht, wie viele Imposter tatsächlich gezogen wurden. Bei drei
bis fünf Personen bleibt die bekannte Einzelauswahl. Ergebnisse nennen alle
Verdächtigen und alle Imposter mit ihren Avataren. Ein- und Mehrzahl werden
entsprechend der erst dann bekannten tatsächlichen Anzahl formuliert.

Gruppenbearbeitung berechnet Zeit und Rollenbereich neu. Eine Folgerunde zieht
Anzahl, Rollen, Hinweise und ein neues Wort erneut, erhält aber die Gruppe und
ihre Avatare. Die Deadline berücksichtigt weiterhin Hintergrundzeit; der
Enthüllungs-Countdown pausiert bei Unterbrechungen und im Verlassensdialog.

Der Katalog behält alle vorhandenen IDs, Wörter und ursprünglichen Hinweise.
Zwei zusätzliche Hinweise pro Wort ergänzen das Format. Der Wortvorrat erkennt
auch Änderungen an zusätzlichen Hinweisen, damit echte Katalogänderungen die
Sitzung korrekt erneuern.

## Validierung

- 97 Unit-/Widget-Tests erfolgreich, einschließlich Staffelgrenzen, möglicher
  Rollenanzahlen, unterschiedlicher Hinweise, exakter Gewinnerbestimmung,
  Geheimnisschutz im Semantikbaum, Gruppenänderung und 200 Prozent Schrift.
- Flutter-Analyse ohne Befund; Format-/Diff-Prüfung erfolgreich.
- Vollständige Erstabnahme: fünf Android-Abläufe auf API 36.1 bei 320 × 568 und 200 Prozent
  Schrift erfolgreich, einschließlich echter 90-Sekunden-Runden und einer
  14-Personen-Runde mit vorgespulter Testuhr.
- Auswahlbegrenzung nach Rückmeldung ergänzt: beide betroffenen Android-Abläufe
  für sechs und vierzehn Personen bei 320 × 568 und 200 Prozent Schrift erneut
  erfolgreich, inklusive gesperrter Zusatzwahl und Freigabe nach Abwahl.
- Roboto-Sichtprüfung der Gruppenzusammenfassung, Karten, Timer,
  Mehrfachauswahl und Ergebnisansichten normal sowie bei 320 × 568 mit
  200 Prozent Schrift erfolgreich.
- Release-APK gebaut, auf Android installiert und kalt gestartet.
  Geheimnisschutz (`SECURE`) und fehlerfreie geprüfte Prozesslogs bestätigt.
  Der gepackte Katalog enthält bytegleich die 100 Wörter mit 300 Hinweisen;
  keine neue Internet-, Kamera- oder Medienberechtigung.
- Physisches Handy, echtes TalkBack und Spielbalance in echten Gruppen bleiben
  eigenständige Praxisprüfungen. Automatisierte Tests belegen keine Spielbalance.
