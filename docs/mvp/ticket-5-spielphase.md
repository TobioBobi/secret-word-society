# Ticket 5 · Zwei-Minuten-Spielphase

Stand: 23.10.2026. Branch `codex/ticket-5-spielphase`, ausgehend von
`origin/main` (`20bc842`, einschließlich Android-Integrationstests aus PR #6).

## Verhalten

- Die letzte Karte führt weiterhin zu „Alle eingeweiht?“ ohne laufende Uhr.
  Erst „2 Minuten starten“ startet die Hinweisphase.
- „Jetzt wird geblufft.“ mit großem Countdown von 02:00 und der Aufforderung,
  reihum Hinweise zu geben, ohne das Wort zu verraten.
- Keine Pause, kein vorzeitiger Abschluss und keine automatische Sprecherwahl.
- App-Wechsel, Fokusverlust und Bildschirmabschaltung halten die Zeit nicht an.
  Bei Rückkehr wird vor dem nächsten Frame die verbleibende Zeit berechnet.
  Ist die Zeit abgelaufen, erscheint direkt die Abstimmungsansicht.
- Bei Ablauf automatisch „Wem vertraut ihr nicht?“ mit Aufforderung zur
  mündlichen Einigung; bei Gleichstand erneut abstimmen. Kein Geheimnis wird
  aufgedeckt. Die Auswahl einer Person und Auflösung folgen in Ticket 6.
- Android-Zurück und „Gruppe bearbeiten“ fragen weiterhin nach dem Verlassen.
  Auch während des Dialogs läuft die Zeit weiter. Abbruch zeigt die dann gültige
  Phase; Bestätigung verwirft Runde und Timer, die Namen bleiben erhalten.
- Prozessneustart beginnt weiterhin mit einer leeren Gruppe.

## Umsetzung

`GameSession` bindet die bestehenden Aktionen `GameRound.startDiscussion` und
`advanceTime` an. Die UI berechnet den Countdown aus dem festen Endzeitpunkt.
Ein periodischer Callback prüft alle 250 ms; neu gerendert wird bei einer
geänderten Sekunde oder Phase. Verbleibende Sekunden werden aufgerundet, damit
die Anzeige unmittelbar vor Ablauf 00:01 zeigt; bei Ablauf wechselt die Ansicht
ohne einen zusätzlichen 00:00-Zustand.

Außerhalb von `resumed` wird der UI-Timer abgebrochen. Die Endzeit bleibt
erhalten und bei jedem Lifecycle-Wechsel werden Zeit und Phase abgeglichen.
Das schließt die bereits sichtbare, noch inaktive Android-Rückkehransicht ein,
bevor `resumed` gemeldet wird. Dafür ist kein Hintergrunddienst nötig.
Timer werden auch beim Verlassen und beim
Entfernen des Widgets beendet. Die Uhr ist für Widget-Tests injizierbar;
die reguläre App und die Integrationstests verwenden `DateTime.now`.

Mehrfach ausgelöste oder veraltete Startaktionen und Aktionen während einer
Unterbrechung oder eines Verlassensdialogs werden ignoriert.

Alle neuen Texte stehen in der deutschen ARB-Datei; keine neue Abhängigkeit.
Der Countdown hat eine lesbare Semantik („Noch … Sekunden“) ohne Live-Region.
Der Phasenwechsel fokussiert die neue Überschrift, solange kein Dialog offen ist.
Die Anzeige nutzt Ziffern gleicher Breite und passt sich bei wenig Platz an.
Androids bestehendes `FLAG_SECURE` bleibt durchgehend aktiv.

## Prüfung

- Alle 40 Unit-/Widget-Tests bestanden; Flutter-Analyse, Dart-Formatprüfung und
  `git diff --check` ohne Befund.
- Sechs neue Widget-Tests für bewussten Start, Mehrfachtippen und alte Callbacks,
  Rundung an der Ablaufgrenze, übersprungene UI-Ticks, alle Lifecycle-Zustände,
  Dialog während des Ablaufs, Verlassen/Neustart und Dispose. Rückkehr nach
  Ablauf auch über `hidden` und `inactive` vor `resumed` abgesichert.
- Geheimnisse in Countdown und Abstimmung verborgen; Zeit zugänglich ohne
  sekündliche Live-Ansage, Überschriftenfokus nach Ablauf geprüft.
- Bereit-Ansicht, Countdown, Abstimmung und Dialoge auf 320 × 568 logischen
  Pixeln bei 200 % Schrift in Widget-Tests geprüft.
- Der bestehende Gerätetest mit echten Assets wartet zusätzlich die regulären
  zwei Minuten bis zur Abstimmungsansicht; siehe [Testanleitung](../testing.md).
  Beide Android-Integrationstests auf `Medium_Phone_API_36.1` bestanden;
  abschließender Lauf ca. 136 Sekunden zuzüglich Build/Installation.
- Release-APK erfolgreich gebaut (ca. 46,7 MB) und im Emulator installiert.
  Countdown und Abstimmungsansicht visuell geprüft. Echter App-Wechsel zeigte
  fortgeschrittene Restzeit (103 auf 59 Sekunden). Mit der normalen Release-App
  den Bildschirm bei 118 Sekunden Restzeit ausgeschaltet und erst nach der Frist
  aufgeweckt: direkt Abstimmungsansicht, kein Geheimnis sichtbar. Dieser native
  Unterbrechungstest wurde separat manuell über ADB durchgeführt; die CI-Suite
  steuert weiterhin keine Android-Systemoberflächen.
- Aktives Fenster weiterhin `SECURE`; keine Flutter-/App-Absturzmeldungen in den
  geprüften Release-Prozesslogs. Android meldet lediglich die systemseitige
  `ashmem`-Deprecation. Lokale QA-Dateien unter `build/qa/` sind nicht versioniert.

Physisches Gerät, echter Screenreader, iOS und die vollständige Runde mit
Namensauswahl/Auflösung sind noch nicht geprüft bzw. gehören zu Folgetickets.
