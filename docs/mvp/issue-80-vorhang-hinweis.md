# Wiederkehrender Vorhanghinweis

Jede neue Spielerkarte deutet die Ziehgeste durch ein dezentes Zupfen des
geschlossenen Vorhangs an. Die erste Person wartet zwei Sekunden. Bei weiteren
Personen beginnt diese Wartezeit erst nach dem abgeschlossenen Spielerbild-Auftritt.
Ein Impuls hebt den Vorhang in 600 Millisekunden bis zu zwölf logische Pixel
an und senkt ihn wieder. Weitere Impulse beginnen im Abstand von vier Sekunden.

Die Bewegung ist unabhängig vom Öffnungszustand. Sie baut keine geheimen Inhalte
auf, bestätigt kein Ansehen und gibt die Karte nicht weiter. Erstes eigenes
Ziehen beendet den Hinweis sofort und dauerhaft für diese Karte, auch nach
Teilöffnung, Abbruch oder Unterbrechung. Auch die zugängliche Aufdeckaktion
beendet den Hinweis. Eine neue Karte beginnt wieder mit dem Hinweis.

Bei reduzierter Bewegung entfällt das Zupfen vollständig. Der vorhandene
statische Hinweis und die Bedienalternativen bleiben erhalten. Hintergrund,
Aussteigedialog und deaktivierte Ticker pausieren den Hinweis; bei Rückkehr
wartet eine noch unberührte Karte erneut zwei Sekunden. Der Spielerbild-Auftritt
wird dadurch nicht neu gestartet.

`test/curtain_hint_test.dart` prüft die sichtbare Bewegung und die Wartezeiten,
Geheimnisverdeckung, Teilöffnung, Kartenwechsel, Unterbrechungen und reduzierte
Bewegung an der Spielerkarte. Bestehende Vorhang- und Übergabetests sichern die
übrigen Gesten sowie Tastatur- und Screenreader-Aktionen ab. Tatsächliche
TalkBack-Ausgabe und die Verständlichkeit beim Weiterreichen an neue Personen
bleiben Praxisprüfungen.
