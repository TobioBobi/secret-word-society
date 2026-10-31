# Rundenende: Ton und Animation

## Verhalten

Beim tatsächlichen Ende der Hinweisphase folgt unverändert die Abstimmung.
Eine limettengrüne Karte „Zeit ist um!“ mit Glocke begleitet den Übergang.
Glocke und Karte bewegen sich einmal über 1,2 Sekunden. Die Karte bleibt danach
ruhig sichtbar. Reduzierte Animationen deaktivieren die Bewegung vollständig.
Wort, Hinweis und Rollen bleiben bis zur regulären Auflösung verborgen.
Auch auf kleinen Displays und bei großer Schrift bleiben die Regeln für die
mündliche Abstimmung und den Gleichstand durch Scrollen erreichbar.

Der eigene, lokal gebündelte Doppelton besteht aus 880 Hz für 320 ms,
120 ms Pause und 1175 Hz für 460 ms, mit weichen Ein-/Ausblendungen.
Er verwendet Androids Benachrichtigungslautstärke. Stumm-/Vibrationsmodus,
Lautstärke null und „Nicht stören“ unterdrücken ihn. Es gibt kein nachträgliches
Abspielen nach dem Aufheben dieser Einstellungen und keine Lautstärkeänderung.

Die Bereit-Ansicht erklärt den Ton und bietet auf Android bei fehlender Freigabe
„Hintergrundton erlauben“ an. Das öffnet die Systemeinstellung für **Alarme und
Erinnerungen**. Ohne Freigabe bleibt das Spiel nutzbar; der Ton ist dann auf die
geöffnete App beschränkt. Die Freigabe wird nach App-Rückkehr erneut geprüft.

## Technische Grenzen und Lebenszyklus

`RoundSignal` plant einen einmaligen, nativen Android-Alarm auf den Endzeitpunkt
der Spielrunde. `setExactAndAllowWhileIdle` mit `ELAPSED_REALTIME_WAKEUP` kann
auch ohne Flutter-Frames und bei ausgeschaltetem Bildschirm auslösen. Android
12 und neuer benötigen dafür `SCHEDULE_EXACT_ALARM`. Es wird keine dauerhafte
Hintergrunddienst-, Benachrichtigungs- oder Nicht-stören-Ausnahme angefordert.
Ein kurzer Wake-Lock während der Wiedergabe lässt den Bildschirm ausgeschaltet.

Die Vordergrund-Abstimmung bietet denselben Alarm zusätzlich zum unmittelbaren
Abschluss an. Beide Wege laufen auf Androids Hauptthread und verbrauchen
dieselbe Rundenkennung genau einmal, auch bei unterdrücktem oder fehlendem Ton.
Der Alarm enthält keine geheimen Spielinformationen. Alte Callbacks passen
nicht zur neuen Kennung. Abbruch, neue Runde, bestätigte Abstimmung und Entfernen
der Spielansicht löschen den Alarm und beenden eine etwaige Wiedergabe.

Die Kennung bleibt nur im Speicher. Wird der App-Prozess beendet, endet wie
bisher die gesamte Spielsitzung; ein eventuell noch zugestellter Systemalarm
spielt daher keinen Ton. Bei Rückkehr wird weder Ton noch Animation nachgeholt.
Ein höchstens zwei Sekunden verspäteter Vordergrundübergang darf noch signalisieren;
ältere akustische Signale werden verworfen. Systemeigene Energiesparmaßnahmen
und die Zustellbegrenzung von Alarmen im Tiefschlaf können einen Ton verhindern.
Sie rechtfertigen kein verspätetes Signal aus einer alten Runde.

Die Rundendauer wird ausschließlich aus dem tatsächlichen Endzeitpunkt der
Spielrunde übernommen. Die temporären zehn Sekunden sowie die offenen
Änderungen in [#22](https://github.com/TobioBobi/secret-word-society/issues/22)
und [#25](https://github.com/TobioBobi/secret-word-society/issues/25) werden
dabei nicht verändert.

## Prüfungen

- Widget-Tests: einmalige Planung/Auslösung, dieselbe Kennung im Abschluss,
  Folgerunden mit eigener Kennung, Abbruch, verspätete Rückkehr, Freigabe und
  erneute Prüfung nach Rückkehr sowie reduzierte Animationen bei 320 × 568
  und 200 Prozent Schrift. Bestehende Timer-/Abstimmungstests bleiben erhalten.
- Reguläre Android-Ablauftests prüfen die neue Zeit-Ende-Karte zusammen mit
  verdeckten Geheimnissen, beiden Gewinnern und frischem Folgerundenstart.
- Lokale Prüfung am 31.10.2026: 73 Unit-/Widget-Tests, die drei regulären
  Android-Ablauftests und Analyse bestanden. Roboto-Sichtprüfung auf 390 × 844
  sowie 320 × 568 bei 200 Prozent Schrift ohne Layoutfehler.
- Separate native Prüfung auf dem Android-Emulator (API 36.1): Ton jeweils
  einmal im Vordergrund, auf dem Homescreen und bei gesperrtem Bildschirm;
  Stummmodus und „Nicht stören“ unterdrücken ihn. Wiederholte Abschlussaufrufe,
  Rückkehr, Abbruch und ersetzte Alarme erzeugen keinen zusätzlichen Ton.
  Ein zehn Sekunden alter Endzeitpunkt wird verworfen. Die tatsächlichen
  MediaPlayer-Starts und Unterdrückungen wurden in den nativen Logs geprüft.
  Hintergrund-Testfristen lagen über Androids Mindestvorlauf für Alarme;
  die regulären Abläufe verwenden unverändert die echte Produktionsdauer.
- Ein physisches Handy, tatsächliche Hörbarkeit in einer lauten Gruppe,
  Hersteller-Energiesparregeln und echtes TalkBack bleiben Praxisprüfungen.

Grundlagen: [Android-Alarme](https://developer.android.com/develop/background-work/services/alarms),
[Audioattribute](https://developer.android.com/reference/android/media/AudioAttributes),
[Nicht-stören-Filter](https://developer.android.com/reference/android/app/NotificationManager#getCurrentInterruptionFilter()).
