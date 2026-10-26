# Ticket 23 · Geheimnisse durch Schieben ansehen

GitHub: [Issue #26](https://github.com/TobioBobi/secret-word-society/issues/26).

## Bedienung

- Den limettenfarbenen Griff am unteren Kartenrand nach oben ziehen und halten.
  Wort bzw. Imposter-Rolle mit Hinweis erscheinen erst bei ausreichend weit
  geöffnetem Vorhang. Die Abdeckung folgt dem Finger im Verhältnis 1:1;
  der mitbewegte Griff bleibt am oberen Anschlag sichtbar. Der Weg ergibt
  sich aus Kartenhöhe minus 64 logischen Pixeln für den Griff (bei normaler
  Schrift 176 Pixel). Ein schneller Swipe beschleunigt die Abdeckung nicht.
- Loslassen, Abbrechen und Zurückziehen verdecken den Inhalt sofort. Nur die
  Abdeckung gleitet beim normalen Loslassen in bis zu 280 Millisekunden
  ruhig zurück, ohne über den Anschlag hinauszulaufen.
  Bei reduzierten Animationen schließt sie sofort.
- Dieselbe Person kann vor der Übergabe beliebig oft nachsehen.
- „Weiter“ wird nach dem ersten Ansehen freigegeben und übergibt verdeckt an
  die nächste Person. Nach der letzten Person folgt die unveränderte Bereit-Phase.
- Die Karte passt ihre Höhe an Schriftgröße und Bildschirm an. Sehr lange
  Inhalte werden bei Platzmangel innerhalb der Lesefläche eingepasst. Außerhalb
  des Griffs bleibt die Seite scrollbar, auch bei 200 Prozent Schrift.

## Barrierefreiheit und Schutz

Die Screenreader-Aktion „Geheimnis kurz ansehen“ öffnet die Karte für acht
Sekunden. Rolle und Inhalt stehen währenddessen in einer Live-Region zum
Vorlesen bereit; erneutes Aktivieren verlängert die Anzeige. Enter und
Leertaste bieten dieselbe zeitlich begrenzte Alternative. Die zeitliche
Begrenzung ist eine Arbeitsentscheidung und muss mit echtem TalkBack erprobt
werden.

App-Unterbrechungen und Verlassensdialoge entfernen private Inhalte sofort aus
Darstellung und Semantikbaum. Sie setzen auch teilweise geöffnete Vorhänge und
laufende Gesten zurück. Eine nach der Rückkehr noch gehaltene alte Geste kann
nichts erneut aufdecken. Die bestehende Android-Screenshotsperre bleibt aktiv.
Private Inhalte werden nicht für die Animation aufbewahrt.

Die Spielzustände trennen Ansehen, Verbergen und Weitergeben. Ein bereits
angesehenes Geheimnis kann im verdeckten Zustand weitergegeben werden; die
Freigabe wird für jede Person zurückgesetzt. Alte oder doppelte Aktionen
können keine Person überspringen. Auch Loslassen vor dem nächsten gerenderten
Frame verdeckt zuverlässig.

## Prüfung

- Modell-/Widget-Tests: wiederholtes Ansehen, Loslassen, Abbruch, teilweise
  geöffnete Gesten bei Unterbrechung, schnelle Aktionen, sichere Übergaben,
  zeitlich begrenzte Semantik- und Tastaturaktion sowie bestehende Rundenabläufe.
  Alle 64 Tests sowie Flutter-Analyse, Format- und Diff-Prüfung bestanden.
  Ein zusätzlicher Regressionstest reproduzierte vor der Korrektur alte
  Pointer-Bewegungen zwischen Rückkehr und erstem Frame; auch dieser Fall
  bleibt nach dem Fix geschlossen.
- Android-Integrationstests: echte Ziehgesten mit Produktionskatalog,
  vollständige Runden für beide Gewinner, Folgerunden und Verlassensdialoge.
  Alle drei Tests auf dem finalen App-Stand erfolgreich; Android-Release-Build
  ebenfalls erfolgreich.
- Sichtprüfung mit Roboto bei normaler Schrift und auf 320 × 568 bei
  200 Prozent Schrift; bestehende Kontrast- und Touchflächenprüfungen.

Physisches Handy, reales TalkBack und Gruppenfeedback bleiben zusätzliche
Abnahmeprüfungen. Automatisierte Semantiktests bestätigen keine tatsächlich
erfolgte Sprachausgabe auf einem echten Gerät.

## CI-Nachbesserung

Der erste PR-Lauf bestand Build, Analyse und Unit-/Widget-Tests. Im zweiten
Android-Ablauf verschwand der Startbutton zwischen Scrollen und Tippen aus dem
Widget-Baum. Die gemeinsame Testhilfe prüft das Ziel nun nach weiteren Frames
erneut auf Sichtbarkeit, Trefferfläche und stabile Position, bevor sie genau
einmal tippt. Ein zusätzlicher Regressionstest reproduziert den Fehler mit
der alten Hilfe und besteht mit der Korrektur. Die Produktbedienung bleibt
unverändert.

Alle 65 Unit-/Widget-Tests, alle drei lokalen Android-Integrationstests,
Analyse, Format- und Diff-Prüfung bestanden nach der Korrektur erneut.

## Rückmeldung zur Schiebebewegung

Die ursprüngliche Übersetzung von 120 Pixeln Fingerweg auf die gesamte
Kartenhöhe wirkte zu leicht und wie Wegwischen. Seit der Nachbesserung folgt
die Abdeckung dem Finger direkt. Der Griff bewegt sich mit und bleibt auch
am oberen Anschlag greifbar. Beim Anhalten bleibt die Abdeckung stehen;
Zurückziehen wirkt sofort, auch nach Überziehen am Anschlag. Der Inhalt liegt
unterhalb des verbleibenden Griffstreifens, sodass Wort und Imposter-Rolle
weiter lesbar bleiben. Ein zusätzlicher Gestentest prüft diese Eigenschaften.
Alle 66 Unit-/Widget-Tests und die Roboto-Sichtprüfung bei normaler sowie
200 Prozent Schrift bestanden mit dieser Anpassung.
