# Sichere Übergabe

Fachlicher Umfang: [Issue #47](https://github.com/TobioBobi/secret-word-society/issues/47).

Der normale Vorhangablauf hat keinen Weiter-Button mehr. Die vollständige
Freilegung merkt das Ansehen vor; erst normales Loslassen und der vollständig
geschlossene Vorhang geben an die nächste Person weiter. Beim Zurückführen mit
gehaltenem Finger bleibt dieselbe Person dran. Teilöffnungen allein genügen nicht.
Erneutes Greifen stoppt den Rücklauf einschließlich seines alten Abschlusses.

`GameRound.canAdvanceCard` verlangt vollständiges Ansehen. Die UI meldet die
Übergabe erst nach dem Schließende; Personenidentität, Rundengruppe und
Unterbrechungsrevision schützen gegen alte Abschlüsse. Unterbrechungen und echte
Gestenabbrüche setzen auch die Ansehen-Freigabe zurück. Die Reihenfolge aus #48
wird beim Weitergeben unverändert durchlaufen.

Die achtsekündige Semantik-/Tastaturanzeige verdeckt bei Zeitablauf ausschließlich.
„Verdecken und weitergeben“ erlaubt die bewusste Übergabe auch nach Zeitablauf.
Die Aktion erscheint bei aktivierter barrierefreier Navigation oder nach einer
Semantik-/Tastaturöffnung. Name, Bild und Aktion bleiben in dieser Bedienart
fest über der Lesefläche. Nach Übergabe erhält die neue Überschrift den Fokus;
die Aufdeckaktion bleibt über Enter, Leertaste und Semantik erreichbar.

Private Semantik wird bereits beim Loslassen gesperrt. Während eines normalen
Rücklaufs bleibt der sichtbare Inhalt fest unter der tatsächlichen gekrümmten
Abdeckung. Unterbrechungen entfernen ihn sofort. Bei reduzierter Bewegung wird
sofort vollständig geschlossen und anschließend gewechselt. Nach der letzten
Person bleibt der bewusste Timerstart in der Bereit-Phase erhalten.

## Prüfung

Die automatisierten Prüfungen verwenden die bestätigten Grenzen `GameSession`
und die bedienbare App-Oberfläche. Dazu gehören Teilöffnungen, Rückführen,
erneutes Greifen ohne Bewegung, Abbruch, Unterbrechungen im Rücklauf, bereits
aufliegende zweite Finger, beide Rollen, erste/letzte Person, zufällige Reihenfolge,
zeitgesteuertes Verdecken, bewusste Tastaturübergabe und Zurücksetzen im Dialog.
Layoutprüfungen berücksichtigen 320 × 568, Systemleisten, lange Namen/Geheimnisse,
200 Prozent Schrift und reduzierte Bewegung. Der Pixelfarbtest für die tatsächlich
gekrümmte Freilegung bleibt erhalten.

Echtes TalkBack und das Weiterreichen auf einem physischen Handy bleiben
Praxistests; Semantikprüfungen bestätigen keine tatsächliche Sprachausgabe.
