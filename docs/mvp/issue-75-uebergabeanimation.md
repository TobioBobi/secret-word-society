# Empfängerhinweis und Avatarauftritt

Bei der Kartenverteilung zeigt die erste Person jeder Runde „Handy an“ über
ihrem vollständigen Namen. Weitere Personen sehen „Gib weiter an“. Der Hinweis
gehört auch bei Screenreader- und Tastaturbedienung zur zentralen Identität;
die Überschrift kündigt Hinweis und Namen gemeinsam an.

Nur der Avatar beziehungsweise das Spielerfoto erhält einen einmaligen,
500 Millisekunden langen Auftritt: von links, rechts, unten oder mit sanftem
Wachsen von kleiner Darstellung zur Normalgröße. Der Bildbereich begrenzt die
Bewegung, damit das Bild den ruhigen Text nicht überlagert. Die endgültige
Identität bleibt sichtbar. Die erste Person erscheint ohne Auftritt.

Eine eigene visuelle Zufallsquelle mischt die vier Varianten. Alle kommen
einmal vor dem nächsten Mischen vor; die zuletzt verwendete Variante wird
an der Mischgrenze ausgeschlossen. Rollenvergabe und Spielerreihenfolge
verwenden diese Quelle nicht. Neuaufbau und erneutes Ansehen derselben
Karte starten keinen neuen Auftritt und ziehen keine weitere Variante.

Der bestehende Vorhang aus #47 entscheidet unverändert über den Wechsel:
erst vollständig ansehen, regulär schließen, dann die nächste Identität
aufbauen. Der Auftritt sperrt weder Ziehgeste noch barrierefreie Aufdeckaktion.
Reduzierte Bewegung zeigt sofort den Endzustand und beendet auch einen bereits
laufenden Auftritt. Kein Ton, keine Vibration und keine zusätzliche Bestätigung.

## Prüfung

`test/handoff_entrances_test.dart` prüft vollständige Mischungen und deren
Grenzen über viele deterministische Zufallsfolgen.
`test/handoff_animation_test.dart` prüft den ruhenden Start, den Wechsel erst
nach vollständigem Schließen, festen Text während der Bewegung und sofortige
Bedienbarkeit. Fotos, lange Namen, 320 × 568 bei 200 Prozent Schrift,
Semantikhinweise, reduzierte Bewegung, vollständige Reihenfolge und die
anschließende Bereit-Ansicht sind enthalten. Die bestehenden Sicherheits- und
Identitätstests prüfen weiterhin Unterbrechungen, Teilöffnungen und Bedienarten.

Tatsächliche TalkBack-Ausgabe und physisches Weiterreichen bleiben
Praxisprüfungen; automatisierte Semantiktests ersetzen diese nicht.
