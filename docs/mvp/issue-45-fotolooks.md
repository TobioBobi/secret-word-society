# Lokale Fotolooks und Cartoon-Accessoires

Umsetzung von Issue #45 auf der gemergten Foto-Grundlage aus PR #44.

## Vorschläge

Die Auswahl enthält insgesamt 40 gleichberechtigte Rezepte: die bisherigen
14 Verzerrungen und 26 neue Vorschläge.

| Bereich | Neue Vorschläge |
| --- | --- |
| Farb-/Grafiklooks | Alien-Grün, Eisblau, Pink, Schwarzweiß, Sepia, Retro, Sonnenuntergang, Poster-Look |
| Accessoires | Riesensonnenbrille, Schnurrbart, Clownsnase, Augenklappe, Krone, Partyhut, Katzenohren, Hasenohren, Zauberhut, Blume |
| Rahmen | Sterne, Konfetti, große Comicsterne |
| Themenlooks | Pirat, Zauberer, Astronaut, Königlich, Disco-Alien |

Pirat kombiniert Hut, Augenklappe und Kragen; Zauberer Hut, Kragen und Sterne;
Astronaut einen offenen Helm mit Kragen; Königlich Krone und Kragen;
Disco-Alien die vorhandene Alien-Verzerrung, Grünlook, Brille und Konfetti.
Die Motive sind bewusst bunte Fotomontagen. Der ursprüngliche Hintergrund
bleibt innerhalb des Fotos sichtbar.

Automatischer Erstvorschlag, Würfeln, Übernehmen und Neuaufnahme bleiben gleich.
Erstzuweisungen sind unabhängig gleichverteilt; beim Würfeln wird ausschließlich
das unmittelbar vorherige Rezept ausgeschlossen. Die Stärke wird weiterhin
zwischen 75 und 125 Prozent gezogen. Accessoires variieren dabei dezent in der
Größe, Farblooks in der Intensität. Schwarzweiß bleibt bei jeder Stärke grau.

## Verarbeitung und Rechte

Alle Motive bestehen aus eigens für das Projekt programmierten Zeichenformen.
Es werden keine externen Grafiken, geschützten Figuren, zusätzlichen Schriften,
Modelle oder Filter-SDKs eingebunden. Die Zeichnungen benötigen keine zusätzlichen
Attributionshinweise; ihre Herkunft ist im mitgelieferten Fotolizenztext vermerkt.
Das vorhandene Paket `image` 4.12.0 bleibt unverändert; dessen vollständige
MIT-Lizenz einschließlich Copyright ist bereits im Flutter-Lizenzpaket enthalten.
Siehe [Paketlizenz](https://pub.dev/packages/image/license).

Es gibt keine neuen Abhängigkeiten, nativen APIs, Berechtigungen, Downloads oder
Netzwerkzugriffe. Vorhandene native SDK-/Modellbedingungen und Datenschutzhinweise
gelten unverändert; insbesondere bleibt die Erklärung möglicher ML-Kit-Metriken
erhalten. Keine Segmentierung oder Beta-/Preview-Funktion kommt hinzu.

Jedes Rezept beginnt beim unveränderten `PhotoSource` im Hintergrund-Isolate.
Reihenfolge: optionale Verzerrung, quadratischer Ausschnitt, Farblook, Accessoires,
Rahmen. Alle Accessoires verwenden dieselbe an der Augenlinie gedrehte Basis;
Nase und Mund werden aus den vorhandenen Merkmalen in diese Basis übertragen.
Disco-Alien verwendet die unverändert verankerten Augenmitten der Alien-Verzerrung.

Alle Effekte verwenden denselben quadratischen Ausschnitt und dieselbe
Vergrößerung wie die bisherigen Verzerrungen. Es wird kein zusätzlicher Rand
angelegt und keine farbige Außenfläche ergänzt. Farblooks färben das Foto
innerhalb des unveränderten Ausschnitts; grafische Rahmen werden darüber
gezeichnet. Hohe Accessoires werden oberhalb der Stirn an den verfügbaren Platz
angepasst, ohne das Foto zu verkleinern. Sitzungsspeicher, Spieler-ID,
temporäre Bereinigung und fehlende Galerie-/Exportfunktion bleiben unverändert.

## Prüfung der ersten Umsetzung am 03.11.2026 (ed490fe)

- 122 Unit-/Widget-Tests, Analyse, Format und Diff-Prüfung erfolgreich.
  Enthalten sind alle 40 Rezepte bei beiden Stärkegrenzen, Unverändertheit der
  Quelle, deterministische Wiederholung, unterschiedliche Ergebnisse, graues
  Schwarzweiß sowie Nasenplatzierung bei Kopfneigung und negativem Ausschnitt.
- Alle Motive bei 75/100/125 Prozent sowie kleine runde Spielerbilder visuell
  geprüft. Vorschau mit langem Effektnamen bei normaler und 200-Prozent-Schrift
  einschließlich beschrifteter Android-Touchflächen geprüft.
- Nativer Kameraablauf mit Aufnahme, Unterbrechung, Rückkehr und Abbruch
  erfolgreich. Der Testemulator benötigte dafür die explizite Aktivierung seiner
  virtuellen Frontkamera.
- Native Android-Fotopipeline mit allen 40 zufälligen Vorschlägen und Bereinigung
  bei erfolgreicher Verarbeitung, keinem/mehreren Gesichtern und ungültigen
  Bilddaten erfolgreich.
- Optimierte Offline-AOT-/R8-Probe: alle 80 Effekt-/Grenzstärkekombinationen
  erfolgreich, beide Spiegelrichtungen eingeschlossen. Keine Modellbeschaffung
  nötig; gebündeltes Modell auch ohne Netzwerk verfügbar.
- Neue Vorschläge ohne Verzerrung: 199–244 ms pro Berechnung im Emulator;
  Disco-Alien: 944–947 ms. Keine Zusage für physische Geräte.
  Alle Test-JPEGs 25.054–57.897 Byte. Gesamtprozess-RSS der Probe vor Verarbeitung
  ca. 163 MiB, danach 223 MiB, Maximum 240 MiB, einschließlich Flutter und ML Kit;
  dies ist keine isolierte Messung des Effektspeichers.

Die unveränderten neun vollständigen Android-Spielabläufe wurden für diese
Erweiterung nicht wiederholt. Echte Selfies mit verschiedenen Personen,
Haut-/Haarfarben, Kopfneigungen, Brillen und Licht sowie tatsächliches TalkBack
bleiben offen. Die technischen und synthetischen Prüfungen ersetzen diese
Praxistests nicht. Remote-CI ist eine getrennte Prüfung.

Die normale Release-App wurde installiert und kalt gestartet; `FLAG_SECURE`
war aktiv und die geprüften Prozesslogs enthielten keine App-Fehler.

Normale universelle Release-APK: 89.895.222 Byte gegenüber 89.731.190 Byte
vor dieser Erweiterung, also +164.032 Byte (ca. 0,18 Prozent). SHA256:
`405BC56F9F8FDCCC48CC53B7473251591B14878E5B6A7BD9B2E8863331312E31`.

## Korrektur: einheitliche Fotogröße

Der Nutzer bestätigt am 03.11.2026: Farblooks und Accessoires sollen das Foto
in derselben Größe wie die Verzerrungen zeigen. Der zuvor eingeführte größere
Ausschnitt mit zusätzlicher Außenfläche ist damit verworfen.

Die bisher separate Ausschnittberechnung für die 26 neuen Vorschläge entfällt.
Alle 40 Rezepte verwenden die bestehende, an den Bildgrenzen begrenzte
Ausschnittberechnung mit Faktor 1,65. Nur hohe Zeichnungsteile über der Stirn
werden vertikal an den verfügbaren Platz angepasst. Gesichtsmerkmale,
Fotoausschnitt und Größe des Gesichts bleiben unverändert.

Der neue Regressionstest vergleicht Bildpunkte eines Farblooks und eines
Accessoires mit dem bekannten bisherigen Fotoausschnitt. Er schlägt vor der
Korrektur fehl und besteht danach. Der Nasenplatzierungstest prüft weiterhin
drei Kopfneigungen, jetzt mit dem gemeinsamen begrenzten Ausschnitt.
123 Unit-/Widget-Tests und Analyse erfolgreich; Effekte bei drei Stärken und
als kleine runde Spielerbilder visuell geprüft.

Die korrigierte Offline-AOT-/R8-Probe besteht mit allen 80 Kombinationen.
Fotoaufnahme, Lifecycle-Bedienung und vollständige Spielabläufe wurden für diese
reine Ausschnittkorrektur nicht erneut nativ getestet. Physischer Praxistest und
TalkBack bleiben offen; Remote-CI wurde noch nicht gestartet.

Korrigierte normale Release-APK: 89.895.222 Byte. SHA256:
`228CB65469FC0B4337A77CF010FC326028C34FE693B2B9337EF4934B9186FEDB`.

Korrigierte normale Release-App installiert und kalt gestartet; `FLAG_SECURE`
aktiv, keine App-Fehler in den geprüften Prozesslogs.
