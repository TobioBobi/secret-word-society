# Gewinner-Sounds

Bei der sichtbaren Auflösung nach „3, 2, 1“ erklingt passend zum ermittelten
Gewinner einmal Jubel mit Applaus (Gruppe) oder ein schelmisches Lachen
(Imposter). Der Doppelton am Ende der Hinweisphase bleibt separat.
[Quellen und Bearbeitung](../audio-credits.md).

Die App bereitet bei bestätigtem Verdacht eine neue Soundkennung vor und
verbraucht sie beim Übergang zum Ergebnis. Der Aufruf erfolgt nach dem ersten
Ergebnis-Frame. Rebuilds und Rückkehr zur Ergebnisansicht spielen nichts erneut.
Der pausierte Enthüllungs-Countdown setzt nach einer Unterbrechung seine
Restzeit fort; erst seine anschließende sichtbare Auflösung darf klingen.
Mehr als zwei Sekunden verspätete Übergänge bleiben stumm.

Android prüft Kennung, Vordergrund und Fensterfokus sowie dieselben
Medienlautstärke-/Stummmodus-/Nicht-stören-Regeln wie beim Timersignal.
Auch ein unterdrückter Aufruf verbraucht seine Kennung. Wiedergabe endet bei
App-Wechsel, Sperre, Rundenwechsel, Abbruch oder Entfernen der Ansicht.
Es gibt keine zusätzliche Berechtigung, Einrichtung oder Wiedergabe im
Hintergrund. Lautstärkeregler und Playerlautstärke werden nicht verändert.

Widget-Tests prüfen die richtige Gewinnerzuordnung, Stille vor Countdownende,
einmaligen Trigger, Rückkehr, pausierten Countdown, veraltete Aktionen,
Abbruch und frische Kennungen in Folgerunden. Native Audio- und Ablaufprüfungen
ergänzen diese Tests; Hörbarkeit und Klangwirkung in einer echten Spielgruppe
bleiben eine Praxisprüfung.

Am 31.10.2026 erfolgreich geprüft: 75 Unit-/Widget-Tests, Analyse, Format und
Diff sowie drei Android-Spielabläufe mit echten Assets und Produktionsuhr.
Native Zusatzprüfung auf API 36.1: beide Clips vollständig abgespielt;
Medienlautstärke null, Stummmodus und „Nicht stören“ unterdrücken den Ton.
Doppelte, veraltete, abgebrochene und ausdrücklich stumme Aufrufe bleiben
wirkungslos. Ein laufender Gruppen-Sound endet beim App-Wechsel, nach Rückkehr
kein Neustart; eine frische Kennung spielt anschließend den Imposter-Sound.
Release-Build, Installation und Kaltstart erfolgreich; alle drei Sounddateien
bytegleich in der APK, Fensterschutz aktiv, keine App-Fehler in den geprüften
Prozesslogs. Echtes Handy, Klangwirkung in Gruppen und TalkBack bleiben offen.
