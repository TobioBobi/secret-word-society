// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Secret Word Society';

  @override
  String get groupPhase => 'Eure Gruppe';

  @override
  String get groupTitle => 'Wer ist dabei?';

  @override
  String get groupIntro =>
      'Ab drei Personen wird geblufft. Tragt euch der Reihe nach ein.';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'Wer spielt noch mit?';

  @override
  String get addName => 'Name hinzufügen';

  @override
  String get nameEmpty => 'Bitte gib einen Namen ein.';

  @override
  String get nameDuplicate =>
      'Dieser Name ist schon dabei. Wählt einen anderen Namen oder Spitznamen.';

  @override
  String get emptyGroup => 'Euer Geheimbund wartet auf die erste Person.';

  @override
  String playerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
      zero: 'Noch keine Personen',
    );
    return '$_temp0';
  }

  @override
  String removePlayer(String name) {
    return '$name entfernen';
  }

  @override
  String playersMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Personen bis zum Start.',
      one: 'Noch 1 Person bis zum Start.',
    );
    return '$_temp0';
  }

  @override
  String get roundSummary => '1 Imposter · 2 Minuten';

  @override
  String get startRound => 'Runde starten';

  @override
  String get startingRound => 'Runde wird vorbereitet …';

  @override
  String get catalogFailed =>
      'Die Wörter konnten nicht geladen werden. Bitte versuche den Rundenstart erneut.';

  @override
  String handoffProgress(int current, int total) {
    return 'Person $current von $total';
  }

  @override
  String handoffTitle(String name) {
    return 'Handy an $name.';
  }

  @override
  String get handoffIntro => 'Nur du schaust auf den Bildschirm.';

  @override
  String get secretConcealed => 'Dein Geheimnis bleibt verdeckt.';

  @override
  String get editGroup => 'Gruppe bearbeiten';

  @override
  String get revealSecret => 'Geheimnis aufdecken';

  @override
  String privateTitle(String name) {
    return 'Nur für $name.';
  }

  @override
  String get privateIntro =>
      'Merke dir deine Karte. Verbirg sie, bevor du das Handy weitergibst.';

  @override
  String get secretWord => 'Dein geheimes Wort';

  @override
  String get imposterRole => 'Du bist der Imposter';

  @override
  String get secretHint => 'Dein Hinweis';

  @override
  String get hideAndPass => 'Verbergen & weitergeben';

  @override
  String get hideAndFinish => 'Verbergen & weiter';

  @override
  String get readyPhase => 'Eure Runde';

  @override
  String get readyTitle => 'Alle eingeweiht?';

  @override
  String get readyIntro =>
      'Gebt reihum einen Hinweis. Verratet das Wort nicht.';

  @override
  String get readyCard => 'Alle Geheimnisse sind verteilt.';

  @override
  String get leaveRoundTitle => 'Runde verlassen?';

  @override
  String get leaveRoundBody =>
      'Die aktuelle Runde wird verworfen. Eure Namen bleiben erhalten.';

  @override
  String get keepPlaying => 'Weiterspielen';

  @override
  String get leaveRound => 'Runde verlassen';
}
