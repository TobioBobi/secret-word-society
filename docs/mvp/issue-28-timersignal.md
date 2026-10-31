# Rundenende: Ton und Animation

## Verhalten

Während des sichtbaren Rundentimers bleibt der Bildschirm automatisch wach.
Die Bereit-Ansicht enthält nur den normalen Rundenstart, ohne Ton-Erklärung,
Einrichtung oder zusätzliche Android-Freigabe.

Beim tatsächlichen Ende der Hinweisphase folgt die Abstimmung. Die
limettengrüne Karte „Zeit ist um!“ bewegt sich einmal über 1,2 Sekunden und
bleibt danach ruhig sichtbar. Reduzierte Animationen schalten die Bewegung ab.
Wort, Hinweis und Rollen bleiben bis zur regulären Auflösung verborgen.

Ein lokal gebündelter Doppelton (880 Hz für 320 ms, 120 ms Pause, 1175 Hz für
460 ms) begleitet den Ablauf in der geöffneten App. Benachrichtigungslautstärke,
Stumm-/Vibrationsmodus und „Nicht stören“ gelten weiterhin.

## Umsetzung und Unterbrechungen

Androids `FLAG_KEEP_SCREEN_ON` ist nur während des sichtbaren Rundentimers aktiv.
Nach Ablauf bleibt er noch für den kurzen Doppelton wach, damit ein bereits
überschrittener Bildschirm-Timeout den Ton nicht abschneidet. Danach sowie bei
Abbruch, App-Wechsel und Entfernen der Spielansicht wird er wieder freigegeben. Bei Rückkehr vor Ablauf wird er für die verbleibende Zeit wieder
wach gehalten. Die manuelle Bildschirmsperre wird nicht verhindert.

Die App fordert weder `SCHEDULE_EXACT_ALARM` noch `WAKE_LOCK` an und verwendet
keinen Alarm-Receiver oder Hintergrunddienst. Es gibt keinen garantierten Ton
bei App-Wechsel oder manueller Sperre. Läuft die Zeit dort ab, erscheint bei
Rückkehr die ruhige Abstimmung ohne nachgeholten Ton oder Animation.

Rundenkennung und Endzeitpunkt verhindern doppelte oder alte Signale.
Unterbrochene Wiedergabe wird beendet; bestätigte Abstimmung und Abbruch
verwerfen den Ton. Ein mehr als zwei Sekunden verspäteter Abschluss bleibt
stumm. Prozessende verwirft wie bisher die gesamte Sitzung.

Die temporären zehn Sekunden sowie die offenen Änderungen in
[#22](https://github.com/TobioBobi/secret-word-society/issues/22) und
[#25](https://github.com/TobioBobi/secret-word-society/issues/25) bleiben unverändert.

## Prüfungen

73 Unit-/Widget-Tests prüfen unter anderem einmaligen Abschluss, Folgerunden,
Abbruch, verspätete Rückkehr, Rückkehr vor Ablauf und reduzierte Animationen bei
320 × 568 mit 200 Prozent Schrift. Die regulären Android-Ablauftests prüfen
vollständige Spielrunden mit echten Assets und der Produktionsuhr; alle drei
Abläufe bestanden am 31.10.2026. Analyse, Format-/Diff-Prüfung und Roboto-
Sichtprüfung bei normaler und 200-Prozent-Schrift waren ebenfalls erfolgreich.

Native Prüfung am 31.10.2026 auf Android API 36.1 bestanden: Der Bildschirm
bleibt bei auf eine Sekunde eingestelltem Timeout über elf Sekunden wach
(Androids Mindest-Timeout beträgt dort zehn Sekunden). Das Fensterflag wird bei
Ablauf, Abbruch, Home und Sperre entfernt. Rückkehr vor Ablauf erlaubt den Ton;
Rückkehr nach Ablauf bleibt stumm. Stummmodus, „Nicht stören“, doppelte Aufrufe,
ersetzte Runden und verspätete Abschlüsse wurden anhand nativer Logs geprüft.
Alle drei vorgesehenen Töne wurden vollständig abgespielt, auch bei bereits
überschrittenem Bildschirm-Timeout; erst danach wurde das Fensterflag entfernt.
Ein physisches Handy, tatsächliche Hörbarkeit in lauten Gruppen und echtes
TalkBack bleiben Praxisprüfungen.

Grundlagen: [Android-Bildschirm wach halten](https://developer.android.com/develop/background-work/background-tasks/awake/screen-on),
[Audioattribute](https://developer.android.com/reference/android/media/AudioAttributes).
