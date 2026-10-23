# Ticket 4 · Geheime Karten sicher herumreichen

Stand: 23.10.2026. Umsetzung auf `codex/ticket-4-geheime-karten`, ausgehend von
`main` mit Ticket 3 und CI (`411afef`).

## Verhalten

- Verdeckte Übergabe mit Name, Fortschritt und „Geheimnis aufdecken“.
- Private Karte mit dem gemeinsamen Wort für die Gruppe oder der expliziten
  Imposter-Rolle und ausschließlich dem zugehörigen Hinweis.
- „Verbergen & weitergeben“ entfernt die Karte und wechselt in einem
  Zustandswechsel zur nächsten verdeckten Übergabe. Es gibt keine Animation,
  Navigationshistorie oder Rückblätterfunktion für private Karten.
- Bei der letzten Person führt „Verbergen & weiter“ zu „Alle eingeweiht?“.
  Die Runde bleibt ohne gestarteten Timer bereit. Der Startbutton und laufende
  Countdown gehören zu Ticket 5; Abstimmung und Ergebnis zu Ticket 6.
- App-Wechsel, Fokusverlust und Bildschirmabschaltung verdecken eine sichtbare
  Karte. Nach Rückkehr ist dieselbe Person dran und muss erneut aufdecken.
- Android-Zurück und „Gruppe bearbeiten“ verdecken zuerst die private Karte;
  erst nach dem verdeckten Frame öffnet „Runde verlassen?“.
  „Weiterspielen“, Dialog-Zurück und Dialogabbruch stellen kein Geheimnis wieder her.
  „Runde verlassen“ verwirft die Runde und erhält die Gruppe.
- Kartenaktionen ignorieren veraltete oder mehrfach ausgelöste Callbacks,
  Aktionen während einer Unterbrechung und bei offenem Verlassensdialog.

## Geheimnisschutz und Aufbau

`GameSession` bietet gezielte Aktionen für die vorhandenen unveränderlichen
`GameRound`-Zustände. Die Ansicht hält keine separate Kopie von Rolle oder Text.
Verdeckte Ansichten enthalten keine privaten Texte im Widget-/Semantikbaum.
Keine Geheimnisse werden in Logs, Routennamen, Restoration oder persistenten
Speicher geschrieben. UI-Texte bleiben in der deutschen ARB-Datei; keine neue
Paketabhängigkeit.

Ein `WidgetsBindingObserver` verdeckt bei jedem Lifecycle-Zustand außer
`resumed`. Hintergrundzustände können Frames aussetzen; beim nächsten Rendern
bleibt ausschließlich die verdeckte Ansicht. Unterbrechungen vor oder nach der
Verteilung verändern die Rundenphase nicht.

Die Android-Activity setzt `FLAG_SECURE` vor `super.onCreate` und lässt es über
die gesamte Laufzeit eingeschaltet. Das schützt auch Spieleranlage und spätere
Ansichten gegen Android-Screenshots. Es verhindert eine asynchrone Schutzlücke
beim Aufdecken und benötigt keinen MethodChannel. Grundlage:
[Android-Dokumentation](https://developer.android.com/security/fraud-prevention/activities)
und [Flutter-Lifecycle](https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver/didChangeAppLifecycleState.html).

Das ist Android-Schutz für das App-Fenster, kein Schutz gegen externe Kameras,
Host-Aufnahmen des Emulators oder jede herstellerspezifische Implementierung.
Eine zukünftige iOS-Anbindung benötigt eine eigene Prüfung.

## Prüfung

- Alle 34 Unit-/Widget-Tests bestanden; `flutter analyze --no-pub --fatal-infos`
  ohne Befund. Dart-Formatierung und `git diff --check` sauber.
- Tests prüfen vollständige Verteilung mit genau einem Hinweis, verdeckte
  Widget-/Semantikbäume, dieselbe Person und Information nach Unterbrechung,
  alle nicht aktiven Lifecycle-Zustände, Dialogabbruch, erneuten Start,
  veraltete Aktionen und Mehrfachtippen. Bestehende Spielkern-Tests bleiben erhalten.
- 320 × 568 logische Pixel bei 200 % Schrift: lange Namen, langes Wort/Hinweis,
  beide Kartentypen, Buttons, Bereit-Ansicht und der scrollbar gestaltete Dialog.
- Debug- und Release-APK lokal erfolgreich gebaut. Die aktuelle Debug-APK wurde
  im Emulator `Medium_Phone_API_36.1` installiert.
  Spieleranlage, Übergabe, Wortkarte, Imposterkarte, Verlassensdialog und Bereit
  visuell geprüft. Karten durch drei Personen verteilt; App-Wechsel,
  Bildschirmabschaltung und Rücknavigation geprüft.
- Aktives Android-Fenster meldet `SECURE`. Ein Android-Screenshot einer
  aufgedeckten Karte zeigt eine schwarze App-Fläche; App-Vorschau nach einer
  aufgedeckten Karte enthält nur die verdeckte Übergabe.
- Keine Laufzeitfehler in den geprüften Logs des aktuellen App-Prozesses.

Lokale QA-Dateien unter `build/qa/` sind nicht versioniert. Kleine Displays und
200 % Schrift wurden in Widget-Tests geprüft. Kein physisches Android-Gerät,
kein echter Screenreader, keine vollständige Spielrunde mit Timer/Abstimmung.
