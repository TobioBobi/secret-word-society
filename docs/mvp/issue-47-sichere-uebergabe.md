# Sichere Übergabe

Fachlicher Umfang: [Issue #47](https://github.com/TobioBobi/secret-word-society/issues/47).

Der normale Vorhangablauf hat keinen Weiter-Button mehr. Seit
[Issue #82](issue-82-textbezogene-weitergabe.md) merkt ungefähr halb sichtbarer
Geheimnistext das Ansehen vor; erst normales Loslassen und der vollständig
geschlossene Vorhang geben an die nächste Person weiter. Beim Zurückführen mit
gehaltenem Finger bleibt dieselbe Person dran. Öffnungen unterhalb der
Textschwelle genügen nicht.
Erneutes Greifen stoppt den Rücklauf einschließlich seines alten Abschlusses.

`GameRound.canAdvanceCard` verlangt die Ansehen-Freigabe. Die UI meldet die
Übergabe erst nach dem Schließende; Personenidentität, Rundengruppe und
Unterbrechungsrevision schützen gegen alte Abschlüsse. Unterbrechungen und echte
Gestenabbrüche setzen auch die Ansehen-Freigabe zurück. Die Reihenfolge aus #48
wird beim Weitergeben unverändert durchlaufen.

Die achtsekündige Semantik-/Tastaturanzeige verdeckt bei Zeitablauf ausschließlich.
„Verdecken und weitergeben“ erlaubt die bewusste Übergabe auch nach Zeitablauf.
Die Aktion erscheint bei aktivierter barrierefreier Navigation oder nach einer
Semantik-/Tastaturöffnung. Avatar und Name stehen bei jeder Bedienart groß und
zentral auf dem geschlossenen Vorhang und bewegen sich beim Öffnen mit ihm;
sie dürfen dabei teilweise aus dem sichtbaren Bereich wandern. Bei Platzmangel
wird zuerst der Avatar verkleinert. Der vollständige Name hat Vorrang und
mehrteilige Namen werden möglichst wortweise umgebrochen. Die Übergabeaktion
steht unter der Identität und bleibt auch auf dem geöffneten Vorhang vollständig
erreichbar, ohne das Geheimnis zu überdecken. Nach Übergabe erhält die neue Überschrift den Fokus;
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

Für die Umsetzung bestehen alle 129 Unit-/Widget-Tests, Flutter-Analyse,
Format- und Diff-Prüfung. Der unabhängige Review gegen den bestätigten
Ausgangsstand ergab auf beiden Achsen (Standards und Spezifikation) keine Befunde.
Die gerenderten Ansichten bei normaler und 200-Prozent-Schrift wurden geprüft;
ein zusätzlicher Regressionstest verhindert Überlappungen zwischen langem Namen
und barrierefreier Übergabeaktion. Alle neun Android-Spielabläufe auf API 36.1
bei 320 × 568 und 200 Prozent Schrift mit reduzierter Bewegung bestanden,
einschließlich beider Gewinner, Folgerunden, Teilöffnungen und Verlassensdialog.
Die gezielte native Übergabeprüfung bestand zusätzlich mit animiertem Rücklauf
und erneut mit reduzierter Bewegung auf dem abschließenden App-Stand. Der
Android-Release-Build ist erfolgreich.

Echtes TalkBack und das Weiterreichen auf einem physischen Handy bleiben
Praxistests; Semantikprüfungen bestätigen keine tatsächliche Sprachausgabe.

## Zentrale Identität nach Bedienfeedback

Am 04.11.2026 bestätigt: dieselbe große, zentrale Anordnung von Avatar und
vollständigem Namen bei jeder Bedienart. Bei wenig Platz hat der Name Vorrang;
der Avatar wird zuerst verkleinert. Die Identität bewegt sich mit dem Vorhang
und darf beim Aufdecken teilweise aus dem sichtbaren Bereich wandern. Die
barrierefreie Übergabeaktion bleibt unter der Identität vollständig erreichbar.

Die separate kompakte obere Zeile wurde entfernt. Textmessung reserviert Platz
für den Namen, bevor die Avatargröße bestimmt wird; mehrteilige Namen werden
wortweise umgebrochen. Bei stark umgebrochener Übergabeaktion berücksichtigt
der Öffnungsweg deren Platzbedarf auf dem angehobenen Vorhang.

Für diese Layoutkorrektur bestanden alle 133 Unit-/Widget-Tests, Analyse,
Format- und Diff-Prüfung. Gerenderte Ansichten mit langen Namen bei normaler
und 200-Prozent-Schrift wurden geschlossen und geöffnet geprüft. Zwei gezielte
Android-Abläufe auf API 36.1 bei 320 × 568 und 200 Prozent Schrift bestätigen
normale Übergaben sowie die Semantikaktion mit Zeitablauf und bewusster Übergabe.
Die neun vollständigen Android-Spielabläufe wurden für diese Layoutkorrektur
nicht erneut ausgeführt; ihr oben dokumentierter Stand gilt für `0856bcd`.
