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
  String get roundSummary => '1 Imposter · 10 Sekunden';

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
  String get peekSecret => 'Geheimnis kurz ansehen';

  @override
  String get peekAccessibilityHint =>
      'Aktivieren zum Ansehen und Vorlesen. Wird nach acht Sekunden automatisch verdeckt.';

  @override
  String get curtainYourTurn => 'Du bist dran';

  @override
  String get curtainInstruction => 'Hochziehen und halten';

  @override
  String get curtainRelease => 'Loslassen verdeckt';

  @override
  String get nextPlayer => 'Weiter';

  @override
  String privateTitle(String name) {
    return 'Nur für $name.';
  }

  @override
  String get privateIntro => 'Nur du schaust auf den Bildschirm.';

  @override
  String get secretWord => 'Dein geheimes Wort';

  @override
  String get imposterRole => 'Du bist der Imposter';

  @override
  String get secretHint => 'Dein Hinweis';

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
  String get timeUpTitle => 'Zeit ist um!';

  @override
  String get startDiscussion => '10 Sekunden starten';

  @override
  String get discussionPhase => 'Hinweise & Bluff';

  @override
  String get discussionTitle => 'Jetzt wird geblufft.';

  @override
  String discussionRemaining(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds Sekunden',
      one: '1 Sekunde',
    );
    return 'Noch $_temp0';
  }

  @override
  String get votingPhase => 'Eure Abstimmung';

  @override
  String get votingTitle => 'Wem vertraut ihr nicht?';

  @override
  String get votingIntro =>
      'Stimmt mündlich ab, wer der Imposter ist. Bei Gleichstand stimmt ihr erneut ab.';

  @override
  String get votingCard => 'Die Zeit ist um. Einigt euch auf eine Person.';

  @override
  String get selectSuspect => 'Person auswählen';

  @override
  String confirmSuspect(String name) {
    return '$name verdächtigen';
  }

  @override
  String get revealPhase => 'Gleich wird enthüllt';

  @override
  String get revealTitle => 'Wer hat geblufft?';

  @override
  String get revealIntro =>
      'Euer Verdacht steht fest. Gleich erfahrt ihr die Wahrheit.';

  @override
  String revealRemaining(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds Sekunden',
      one: '1 Sekunde',
    );
    return 'Enthüllung in $_temp0';
  }

  @override
  String get resultPhase => 'Die Auflösung';

  @override
  String get groupWinTitle => 'Erwischt!';

  @override
  String get imposterWinTitle => 'Gut geblufft!';

  @override
  String get groupWinIntro => 'Ihr habt den Imposter entlarvt.';

  @override
  String get imposterWinIntro => 'Der Imposter hat euch ausgetrickst.';

  @override
  String get groupWins => 'Die Gruppe gewinnt.';

  @override
  String get imposterWins => 'Der Imposter gewinnt.';

  @override
  String get resultSuspect => 'Euer Verdacht';

  @override
  String get resultImposter => 'Der Imposter war';

  @override
  String get resultWord => 'Das geheime Wort';

  @override
  String get nextRound => 'Noch eine Runde';

  @override
  String get leaveRoundTitle => 'Runde verlassen?';

  @override
  String get leaveRoundBody =>
      'Die aktuelle Runde wird verworfen. Eure Namen bleiben erhalten.';

  @override
  String get keepPlaying => 'Weiterspielen';

  @override
  String get leaveRound => 'Runde verlassen';

  @override
  String rerollAvatar(String name) {
    return 'Neuer Avatar für $name';
  }

  @override
  String get renamePlayer => 'Name ändern';

  @override
  String get cancelEdit => 'Abbrechen';

  @override
  String get saveName => 'Übernehmen';
}
