# Textbezogene Weitergabeschwelle

Umfang: [Issue #82](https://github.com/TobioBobi/secret-word-society/issues/82).
Ersetzt die bisherige Vollöffnungsanforderung aus #47 für die Weitergabe.

Beim Ziehen gilt die Karte als angesehen, sobald die gekrümmte Vorhangkante
die Mitte des eigentlichen Geheimnistexts erreicht. Gemessen wird der gerenderte
Wort-/Hinweistext einschließlich Umbrüchen, Systemschrift und Einpassskalierung.
Rollenüberschrift und Beschriftungen zählen nicht zur Texthöhe. Die Kurve wird
an der horizontalen Textmitte ausgewertet; die Freigabe liegt damit bei ungefähr
halb sichtbarem Geheimnistext statt bei 95 Prozent des Vorhangwegs.

Diese Freigabe bleibt beim normalen Zurückziehen erhalten. Loslassen schließt
den Vorhang und wechselt erst nach vollständigem Schließen zur nächsten Person.
Nach der letzten Person folgt die Bereit-Ansicht. Unterhalb der Textschwelle bleibt
dieselbe Person dran. Ein sichtbarer Weitergabebutton verwendet dieselbe Freigabe.

Die bisherige Vollöffnungsschwelle bleibt für Textpositionierung und private
Semantik erhalten. Zugängliches Aufdecken per Screenreader oder Tastatur
öffnet weiterhin vollständig. Abbruch, Dialog und App-Unterbrechung verdecken
und setzen die Freigabe zurück. Der visuelle Zupfhinweis verändert sie nicht.

`test/text_handoff_test.dart` prüft die Freigabe mit der tatsächlich gerenderten
Kurvenmaske: unterhalb/oberhalb der Textmitte, beide Rollen und letzte Person,
normale und kleine Anzeige mit großer Schrift, mehrzeilige Texte, sichtbare
Buttonfreigabe, Zurückziehen, reduzierte Bewegung und Unterbrechungen.
Bestehende Vorhangtests sichern Tastatur-/Semantikaktionen und den Zupfhinweis ab.
Echte TalkBack-Ausgabe und Bediengefühl auf einem physischen Handy bleiben
Praxisprüfungen.
