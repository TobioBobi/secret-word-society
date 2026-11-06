import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de')];

  /// No description provided for @play.
  ///
  /// In de, this message translates to:
  /// **'Spielen'**
  String get play;

  /// No description provided for @gameGuide.
  ///
  /// In de, this message translates to:
  /// **'Spielanleitung'**
  String get gameGuide;

  /// No description provided for @guideRevealTitle.
  ///
  /// In de, this message translates to:
  /// **'1. Geheimnisse ansehen'**
  String get guideRevealTitle;

  /// No description provided for @guideReveal.
  ///
  /// In de, this message translates to:
  /// **'Schaut euch reihum eure geheime Karte am selben Handy an. Verdeckt die Karte, bevor ihr das Handy weitergebt. Die Gruppe kennt das geheime Wort. Der Imposter sieht seine Rolle und einen Hinweis und blufft mit.'**
  String get guideReveal;

  /// No description provided for @guideGroupCard.
  ///
  /// In de, this message translates to:
  /// **'Gruppe · Wort'**
  String get guideGroupCard;

  /// No description provided for @guideImposterCard.
  ///
  /// In de, this message translates to:
  /// **'Imposter · Hinweis'**
  String get guideImposterCard;

  /// No description provided for @guideExampleWord.
  ///
  /// In de, this message translates to:
  /// **'Popcorn'**
  String get guideExampleWord;

  /// No description provided for @guideExampleHint.
  ///
  /// In de, this message translates to:
  /// **'Kino'**
  String get guideExampleHint;

  /// No description provided for @guideDiscussTitle.
  ///
  /// In de, this message translates to:
  /// **'2. Hinweise geben'**
  String get guideDiscussTitle;

  /// No description provided for @guideDiscuss.
  ///
  /// In de, this message translates to:
  /// **'Während der Timer läuft, gibt jede Person reihum einen eigenen Hinweis, ohne das Wort zu verraten. Im Beispiel sagt jemand aus der Gruppe „knusprig“. Der Imposter blufft mit „Filmpause“.'**
  String get guideDiscuss;

  /// No description provided for @guideSkip.
  ///
  /// In de, this message translates to:
  /// **'Wenn ihr fertig seid, könnt ihr den Timer überspringen.'**
  String get guideSkip;

  /// No description provided for @guideVoteTitle.
  ///
  /// In de, this message translates to:
  /// **'3. Verdacht bestätigen'**
  String get guideVoteTitle;

  /// No description provided for @guideVote.
  ///
  /// In de, this message translates to:
  /// **'Stimmt mündlich ab, wen ihr verdächtigt. Bei Gleichstand stimmt ihr erneut ab. Wählt dann die verdächtigte Person oder die verdächtigten Personen in der App aus und bestätigt euren gemeinsamen Verdacht.'**
  String get guideVote;

  /// No description provided for @guideResultTitle.
  ///
  /// In de, this message translates to:
  /// **'4. Auflösung'**
  String get guideResultTitle;

  /// No description provided for @guideResult.
  ///
  /// In de, this message translates to:
  /// **'Die App zeigt das Wort und wer Imposter war. Die Gruppe gewinnt, wenn sie genau alle Imposter ausgewählt hat. Sonst gewinnen die Imposter. Das gilt auch bei mehreren Impostern.'**
  String get guideResult;

  /// No description provided for @guideExampleResult.
  ///
  /// In de, this message translates to:
  /// **'Im Beispiel bestätigt die Gruppe die Person, die „Filmpause“ gesagt hat. Die App löst auf: Das Wort war „Popcorn“, diese Person war der einzige Imposter. Die Gruppe gewinnt.'**
  String get guideExampleResult;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @imposterCount.
  ///
  /// In de, this message translates to:
  /// **'Imposter-Anzahl'**
  String get imposterCount;

  /// No description provided for @moreImposters.
  ///
  /// In de, this message translates to:
  /// **'Mehr Imposter'**
  String get moreImposters;

  /// No description provided for @fewerImposters.
  ///
  /// In de, this message translates to:
  /// **'Weniger Imposter'**
  String get fewerImposters;

  /// No description provided for @selectedImposters.
  ///
  /// In de, this message translates to:
  /// **'Imposter-Anzahl: {count}'**
  String selectedImposters(String count);

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Secret Word Society'**
  String get appTitle;

  /// No description provided for @groupPhase.
  ///
  /// In de, this message translates to:
  /// **'Eure Gruppe'**
  String get groupPhase;

  /// No description provided for @groupTitle.
  ///
  /// In de, this message translates to:
  /// **'Wer ist dabei?'**
  String get groupTitle;

  /// No description provided for @groupIntro.
  ///
  /// In de, this message translates to:
  /// **'Ab drei Personen wird geblufft. Tragt euch der Reihe nach ein.'**
  String get groupIntro;

  /// No description provided for @nameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In de, this message translates to:
  /// **'Wer spielt noch mit?'**
  String get nameHint;

  /// No description provided for @addName.
  ///
  /// In de, this message translates to:
  /// **'Name hinzufügen'**
  String get addName;

  /// No description provided for @nameEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen ein.'**
  String get nameEmpty;

  /// No description provided for @nameDuplicate.
  ///
  /// In de, this message translates to:
  /// **'Dieser Name ist schon dabei. Wählt einen anderen Namen oder Spitznamen.'**
  String get nameDuplicate;

  /// No description provided for @emptyGroup.
  ///
  /// In de, this message translates to:
  /// **'Euer Geheimbund wartet auf die erste Person.'**
  String get emptyGroup;

  /// No description provided for @playerCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch keine Personen} =1{1 Person} other{{count} Personen}}'**
  String playerCount(int count);

  /// No description provided for @removePlayer.
  ///
  /// In de, this message translates to:
  /// **'{name} entfernen'**
  String removePlayer(String name);

  /// No description provided for @playersMissing.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Noch 1 Person bis zum Start.} other{Noch {count} Personen bis zum Start.}}'**
  String playersMissing(int count);

  /// No description provided for @roundSummary.
  ///
  /// In de, this message translates to:
  /// **'{imposters} Imposter · {duration} Minuten'**
  String roundSummary(String imposters, String duration);

  /// No description provided for @startRound.
  ///
  /// In de, this message translates to:
  /// **'Runde starten'**
  String get startRound;

  /// No description provided for @roundDuration.
  ///
  /// In de, this message translates to:
  /// **'Rundendauer'**
  String get roundDuration;

  /// No description provided for @shortenDuration.
  ///
  /// In de, this message translates to:
  /// **'30 Sekunden kürzer'**
  String get shortenDuration;

  /// No description provided for @extendDuration.
  ///
  /// In de, this message translates to:
  /// **'30 Sekunden länger'**
  String get extendDuration;

  /// No description provided for @selectedDuration.
  ///
  /// In de, this message translates to:
  /// **'Rundendauer: {duration} Minuten'**
  String selectedDuration(String duration);

  /// No description provided for @startingRound.
  ///
  /// In de, this message translates to:
  /// **'Runde wird vorbereitet …'**
  String get startingRound;

  /// No description provided for @catalogFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Wörter konnten nicht geladen werden. Bitte versuche den Rundenstart erneut.'**
  String get catalogFailed;

  /// No description provided for @handoffProgress.
  ///
  /// In de, this message translates to:
  /// **'Person {current} von {total}'**
  String handoffProgress(int current, int total);

  /// No description provided for @handoffTitle.
  ///
  /// In de, this message translates to:
  /// **'Handy an {name}.'**
  String handoffTitle(String name);

  /// No description provided for @handoffIntro.
  ///
  /// In de, this message translates to:
  /// **'Nur du schaust auf den Bildschirm.'**
  String get handoffIntro;

  /// No description provided for @secretConcealed.
  ///
  /// In de, this message translates to:
  /// **'Dein Geheimnis bleibt verdeckt.'**
  String get secretConcealed;

  /// No description provided for @editGroup.
  ///
  /// In de, this message translates to:
  /// **'Gruppe bearbeiten'**
  String get editGroup;

  /// No description provided for @peekSecret.
  ///
  /// In de, this message translates to:
  /// **'Geheimnis kurz ansehen'**
  String get peekSecret;

  /// No description provided for @peekAccessibilityHint.
  ///
  /// In de, this message translates to:
  /// **'Aktivieren zum Ansehen und Vorlesen. Wird nach acht Sekunden automatisch verdeckt.'**
  String get peekAccessibilityHint;

  /// No description provided for @curtainYourTurn.
  ///
  /// In de, this message translates to:
  /// **'Du bist dran'**
  String get curtainYourTurn;

  /// No description provided for @curtainInstruction.
  ///
  /// In de, this message translates to:
  /// **'Hochziehen und halten'**
  String get curtainInstruction;

  /// No description provided for @curtainRelease.
  ///
  /// In de, this message translates to:
  /// **'Loslassen verdeckt'**
  String get curtainRelease;

  /// No description provided for @nextPlayer.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get nextPlayer;

  /// No description provided for @concealAndHandoff.
  ///
  /// In de, this message translates to:
  /// **'Verdecken und weitergeben'**
  String get concealAndHandoff;

  /// No description provided for @privateTitle.
  ///
  /// In de, this message translates to:
  /// **'Nur für {name}.'**
  String privateTitle(String name);

  /// No description provided for @privateIntro.
  ///
  /// In de, this message translates to:
  /// **'Nur du schaust auf den Bildschirm.'**
  String get privateIntro;

  /// No description provided for @secretWord.
  ///
  /// In de, this message translates to:
  /// **'Dein geheimes Wort'**
  String get secretWord;

  /// No description provided for @imposterRole.
  ///
  /// In de, this message translates to:
  /// **'Du bist der Imposter'**
  String get imposterRole;

  /// No description provided for @secretHint.
  ///
  /// In de, this message translates to:
  /// **'Dein Hinweis'**
  String get secretHint;

  /// No description provided for @readyPhase.
  ///
  /// In de, this message translates to:
  /// **'Eure Runde'**
  String get readyPhase;

  /// No description provided for @readyTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle eingeweiht?'**
  String get readyTitle;

  /// No description provided for @readyIntro.
  ///
  /// In de, this message translates to:
  /// **'Gebt reihum einen Hinweis. Verratet das Wort nicht.'**
  String get readyIntro;

  /// No description provided for @readyCard.
  ///
  /// In de, this message translates to:
  /// **'Alle Geheimnisse sind verteilt.'**
  String get readyCard;

  /// No description provided for @timeUpTitle.
  ///
  /// In de, this message translates to:
  /// **'Zeit ist um!'**
  String get timeUpTitle;

  /// No description provided for @startDiscussion.
  ///
  /// In de, this message translates to:
  /// **'{duration} starten'**
  String startDiscussion(String duration);

  /// No description provided for @discussionPhase.
  ///
  /// In de, this message translates to:
  /// **'Hinweise & Bluff'**
  String get discussionPhase;

  /// No description provided for @discussionTitle.
  ///
  /// In de, this message translates to:
  /// **'Jetzt wird geblufft.'**
  String get discussionTitle;

  /// No description provided for @discussionRemaining.
  ///
  /// In de, this message translates to:
  /// **'Noch {seconds, plural, =1{1 Sekunde} other{{seconds} Sekunden}}'**
  String discussionRemaining(int seconds);

  /// No description provided for @votingPhase.
  ///
  /// In de, this message translates to:
  /// **'Eure Abstimmung'**
  String get votingPhase;

  /// No description provided for @votingTitle.
  ///
  /// In de, this message translates to:
  /// **'Wem vertraut ihr nicht?'**
  String get votingTitle;

  /// No description provided for @votingIntro.
  ///
  /// In de, this message translates to:
  /// **'Stimmt mündlich ab, wer der Imposter ist. Bei Gleichstand stimmt ihr erneut ab.'**
  String get votingIntro;

  /// No description provided for @votingCard.
  ///
  /// In de, this message translates to:
  /// **'Die Zeit ist um. Einigt euch auf eine Person.'**
  String get votingCard;

  /// No description provided for @selectSuspect.
  ///
  /// In de, this message translates to:
  /// **'Person auswählen'**
  String get selectSuspect;

  /// No description provided for @confirmSuspect.
  ///
  /// In de, this message translates to:
  /// **'{name} verdächtigen'**
  String confirmSuspect(String name);

  /// No description provided for @revealPhase.
  ///
  /// In de, this message translates to:
  /// **'Gleich wird enthüllt'**
  String get revealPhase;

  /// No description provided for @revealTitle.
  ///
  /// In de, this message translates to:
  /// **'Wer hat geblufft?'**
  String get revealTitle;

  /// No description provided for @revealIntro.
  ///
  /// In de, this message translates to:
  /// **'Euer Verdacht steht fest. Gleich erfahrt ihr die Wahrheit.'**
  String get revealIntro;

  /// No description provided for @revealRemaining.
  ///
  /// In de, this message translates to:
  /// **'Enthüllung in {seconds, plural, =1{1 Sekunde} other{{seconds} Sekunden}}'**
  String revealRemaining(int seconds);

  /// No description provided for @resultPhase.
  ///
  /// In de, this message translates to:
  /// **'Die Auflösung'**
  String get resultPhase;

  /// No description provided for @groupWinTitle.
  ///
  /// In de, this message translates to:
  /// **'Erwischt!'**
  String get groupWinTitle;

  /// No description provided for @imposterWinTitle.
  ///
  /// In de, this message translates to:
  /// **'Gut geblufft!'**
  String get imposterWinTitle;

  /// No description provided for @groupWinIntro.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Ihr habt den Imposter entlarvt.} other{Ihr habt alle Imposter entlarvt.}}'**
  String groupWinIntro(int count);

  /// No description provided for @imposterWinIntro.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Der Imposter hat euch ausgetrickst.} other{Die Imposter haben euch ausgetrickst.}}'**
  String imposterWinIntro(int count);

  /// No description provided for @groupWins.
  ///
  /// In de, this message translates to:
  /// **'Die Gruppe gewinnt.'**
  String get groupWins;

  /// No description provided for @imposterWins.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Der Imposter gewinnt.} other{Die Imposter gewinnen.}}'**
  String imposterWins(int count);

  /// No description provided for @resultSuspect.
  ///
  /// In de, this message translates to:
  /// **'Euer Verdacht'**
  String get resultSuspect;

  /// No description provided for @resultImposter.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Der Imposter war} other{Die Imposter waren}}'**
  String resultImposter(int count);

  /// No description provided for @resultWord.
  ///
  /// In de, this message translates to:
  /// **'Das geheime Wort'**
  String get resultWord;

  /// No description provided for @nextRound.
  ///
  /// In de, this message translates to:
  /// **'Noch eine Runde'**
  String get nextRound;

  /// No description provided for @leaveRoundTitle.
  ///
  /// In de, this message translates to:
  /// **'Runde verlassen?'**
  String get leaveRoundTitle;

  /// No description provided for @skipTimer.
  ///
  /// In de, this message translates to:
  /// **'Timer überspringen'**
  String get skipTimer;

  /// No description provided for @skipTimerTitle.
  ///
  /// In de, this message translates to:
  /// **'Timer überspringen?'**
  String get skipTimerTitle;

  /// No description provided for @leaveRoundBody.
  ///
  /// In de, this message translates to:
  /// **'Die aktuelle Runde wird verworfen. Eure Namen bleiben erhalten.'**
  String get leaveRoundBody;

  /// No description provided for @keepPlaying.
  ///
  /// In de, this message translates to:
  /// **'Weiterspielen'**
  String get keepPlaying;

  /// No description provided for @leaveRound.
  ///
  /// In de, this message translates to:
  /// **'Runde verlassen'**
  String get leaveRound;

  /// No description provided for @rerollAvatar.
  ///
  /// In de, this message translates to:
  /// **'Neuer Avatar für {name}'**
  String rerollAvatar(String name);

  /// No description provided for @renamePlayer.
  ///
  /// In de, this message translates to:
  /// **'Name ändern'**
  String get renamePlayer;

  /// No description provided for @cancelEdit.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancelEdit;

  /// No description provided for @saveName.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get saveName;

  /// No description provided for @groupFull.
  ///
  /// In de, this message translates to:
  /// **'Eure Gruppe ist mit 14 Personen vollständig.'**
  String get groupFull;

  /// No description provided for @multipleImposterRole.
  ///
  /// In de, this message translates to:
  /// **'Du bist ein Imposter'**
  String get multipleImposterRole;

  /// No description provided for @multipleVotingIntro.
  ///
  /// In de, this message translates to:
  /// **'Findet alle Imposter. Stimmt mündlich ab und wählt nur die Personen aus, die ihr verdächtigt. Bei Gleichstand stimmt ihr erneut ab.'**
  String get multipleVotingIntro;

  /// No description provided for @multipleVotingCard.
  ///
  /// In de, this message translates to:
  /// **'Die Zeit ist um. Für den Gruppensieg müsst ihr alle Imposter und keine andere Person auswählen.'**
  String get multipleVotingCard;

  /// No description provided for @confirmSuspects.
  ///
  /// In de, this message translates to:
  /// **'{count} Personen verdächtigen'**
  String confirmSuspects(int count);

  /// No description provided for @photoFor.
  ///
  /// In de, this message translates to:
  /// **'Foto für {name}'**
  String photoFor(String name);

  /// No description provided for @photoPosition.
  ///
  /// In de, this message translates to:
  /// **'Halte dein Gesicht in den ovalen Rahmen und löse selbst aus.'**
  String get photoPosition;

  /// No description provided for @photoPreview.
  ///
  /// In de, this message translates to:
  /// **'Vorschau des Spielerfotos'**
  String get photoPreview;

  /// No description provided for @photoWorking.
  ///
  /// In de, this message translates to:
  /// **'Foto wird verarbeitet'**
  String get photoWorking;

  /// No description provided for @photoPermission.
  ///
  /// In de, this message translates to:
  /// **'Kein Kamerazugriff. Du kannst mit deinem bisherigen Bild weiterspielen. Erlaube die Kamera bei Bedarf in den Android-App-Einstellungen.'**
  String get photoPermission;

  /// No description provided for @photoNoCamera.
  ///
  /// In de, this message translates to:
  /// **'Keine Frontkamera verfügbar. Spiele mit deinem bisherigen Bild weiter.'**
  String get photoNoCamera;

  /// No description provided for @photoNoFace.
  ///
  /// In de, this message translates to:
  /// **'Kein Gesicht erkannt. Halte dein Gesicht gut beleuchtet in den Rahmen und nimm erneut auf.'**
  String get photoNoFace;

  /// No description provided for @photoManyFaces.
  ///
  /// In de, this message translates to:
  /// **'Mehrere Gesichter erkannt. Bitte nur eine Person aufnehmen.'**
  String get photoManyFaces;

  /// No description provided for @photoLandmarks.
  ///
  /// In de, this message translates to:
  /// **'Gesicht nicht deutlich erkannt. Schau gerade in die Kamera und nimm erneut auf.'**
  String get photoLandmarks;

  /// No description provided for @photoFailed.
  ///
  /// In de, this message translates to:
  /// **'Das Foto konnte nicht verarbeitet werden. Bitte erneut versuchen.'**
  String get photoFailed;

  /// No description provided for @takePhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get takePhoto;

  /// No description provided for @photoRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get photoRetry;

  /// No description provided for @usePhoto.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get usePhoto;

  /// No description provided for @rollEffect.
  ///
  /// In de, this message translates to:
  /// **'Effekt würfeln'**
  String get rollEffect;

  /// No description provided for @retakePhoto.
  ///
  /// In de, this message translates to:
  /// **'Neu aufnehmen'**
  String get retakePhoto;

  /// No description provided for @cancelPhoto.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancelPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto entfernen'**
  String get removePhoto;

  /// No description provided for @effectNose.
  ///
  /// In de, this message translates to:
  /// **'Große Nase'**
  String get effectNose;

  /// No description provided for @effectEyes.
  ///
  /// In de, this message translates to:
  /// **'Große Augen'**
  String get effectEyes;

  /// No description provided for @effectWide.
  ///
  /// In de, this message translates to:
  /// **'Breites Gesicht'**
  String get effectWide;

  /// No description provided for @effectSwirl.
  ///
  /// In de, this message translates to:
  /// **'Strudel'**
  String get effectSwirl;

  /// No description provided for @privacyAndLicenses.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz und Lizenzen'**
  String get privacyAndLicenses;

  /// No description provided for @licenses.
  ///
  /// In de, this message translates to:
  /// **'Lizenzen'**
  String get licenses;

  /// No description provided for @photoPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Spielerfotos sind freiwillig. Die Kamera wird nur für deine Aufnahme geöffnet. Bilder und erkannte Gesichtsmerkmale werden auf diesem Gerät verarbeitet und nicht hochgeladen. Ausgangsfoto und gefiltertes Bild bleiben nur in der laufenden Spielgruppe; beim Ersetzen, Entfernen oder Beenden der Sitzung werden sie freigegeben. Es gibt keine Galerieablage und keinen Export. Temporäre Aufnahmedateien werden nach der Verarbeitung gelöscht; nach einem unerwarteten Prozessende beim nächsten App-Start.\n\nDie Gesichtserkennung verwendet Google ML Kit mit einem mitgelieferten Modell und funktioniert auch bei der ersten Nutzung offline. Laut Google kann das SDK Geräte- und App-Informationen sowie Nutzungs- und Leistungsmetriken an Google senden und Server für Updates kontaktieren. Fotos und Erkennungsergebnisse werden dabei nicht an Google gesendet. Google verarbeitet diese Metriken für Diagnose, Wartung und Verbesserung der APIs.\n\nWeitere Informationen: https://developers.google.com/ml-kit/terms und https://policies.google.com/privacy. Die Lizenzansicht enthält außerdem die Bedingungen und Quellen der verwendeten Bibliotheken.'**
  String get photoPrivacy;

  /// No description provided for @photoCaptureFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Kamera konnte kein Foto aufnehmen. Bitte erneut versuchen.'**
  String get photoCaptureFailed;

  /// No description provided for @photoDecodeFailed.
  ///
  /// In de, this message translates to:
  /// **'Das aufgenommene Bild konnte nicht gelesen werden. Bitte neu aufnehmen.'**
  String get photoDecodeFailed;

  /// No description provided for @photoDetectionFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Gesichtserkennung konnte nicht gestartet werden. Bitte erneut versuchen.'**
  String get photoDetectionFailed;

  /// No description provided for @photoEffectFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Fotoeffekt konnte nicht berechnet werden. Bitte erneut würfeln oder neu aufnehmen.'**
  String get photoEffectFailed;

  /// No description provided for @effectAlien.
  ///
  /// In de, this message translates to:
  /// **'Alien'**
  String get effectAlien;

  /// No description provided for @effectCheeks.
  ///
  /// In de, this message translates to:
  /// **'Hamsterbacken'**
  String get effectCheeks;

  /// No description provided for @effectGrin.
  ///
  /// In de, this message translates to:
  /// **'Riesengrinsen'**
  String get effectGrin;

  /// No description provided for @effectEgghead.
  ///
  /// In de, this message translates to:
  /// **'Eierkopf'**
  String get effectEgghead;

  /// No description provided for @effectSquashed.
  ///
  /// In de, this message translates to:
  /// **'Quetschkopf'**
  String get effectSquashed;

  /// No description provided for @effectAsymmetric.
  ///
  /// In de, this message translates to:
  /// **'Schiefgesicht'**
  String get effectAsymmetric;

  /// No description provided for @effectMini.
  ///
  /// In de, this message translates to:
  /// **'Mini-Gesicht'**
  String get effectMini;

  /// No description provided for @effectMirror.
  ///
  /// In de, this message translates to:
  /// **'Spiegelgesicht'**
  String get effectMirror;

  /// No description provided for @effectJelly.
  ///
  /// In de, this message translates to:
  /// **'Wackelpudding'**
  String get effectJelly;

  /// No description provided for @effectFisheye.
  ///
  /// In de, this message translates to:
  /// **'Fischauge'**
  String get effectFisheye;

  /// No description provided for @effectGreen.
  ///
  /// In de, this message translates to:
  /// **'Grüner Alien'**
  String get effectGreen;

  /// No description provided for @effectIce.
  ///
  /// In de, this message translates to:
  /// **'Eisaugen'**
  String get effectIce;

  /// No description provided for @effectPink.
  ///
  /// In de, this message translates to:
  /// **'Pinke Hamsterbacken'**
  String get effectPink;

  /// No description provided for @effectMono.
  ///
  /// In de, this message translates to:
  /// **'Schwarzweiß-Fischauge'**
  String get effectMono;

  /// No description provided for @effectSepia.
  ///
  /// In de, this message translates to:
  /// **'Sepia-Schnurrbart'**
  String get effectSepia;

  /// No description provided for @effectRetro.
  ///
  /// In de, this message translates to:
  /// **'Retro-Brille'**
  String get effectRetro;

  /// No description provided for @effectSunset.
  ///
  /// In de, this message translates to:
  /// **'Sonnenparty'**
  String get effectSunset;

  /// No description provided for @effectComic.
  ///
  /// In de, this message translates to:
  /// **'Comicgrinsen'**
  String get effectComic;

  /// No description provided for @effectSunglasses.
  ///
  /// In de, this message translates to:
  /// **'Riesensonnenbrille'**
  String get effectSunglasses;

  /// No description provided for @effectMoustache.
  ///
  /// In de, this message translates to:
  /// **'Schnurrbart'**
  String get effectMoustache;

  /// No description provided for @effectClown.
  ///
  /// In de, this message translates to:
  /// **'Clownsnase'**
  String get effectClown;

  /// No description provided for @effectPatch.
  ///
  /// In de, this message translates to:
  /// **'Augenklappe'**
  String get effectPatch;

  /// No description provided for @effectCrown.
  ///
  /// In de, this message translates to:
  /// **'Krone'**
  String get effectCrown;

  /// No description provided for @effectPartyHat.
  ///
  /// In de, this message translates to:
  /// **'Partyhut'**
  String get effectPartyHat;

  /// No description provided for @effectCatEars.
  ///
  /// In de, this message translates to:
  /// **'Katzenohren'**
  String get effectCatEars;

  /// No description provided for @effectBunnyEars.
  ///
  /// In de, this message translates to:
  /// **'Hasenohren'**
  String get effectBunnyEars;

  /// No description provided for @effectFlower.
  ///
  /// In de, this message translates to:
  /// **'Blume'**
  String get effectFlower;

  /// No description provided for @effectStars.
  ///
  /// In de, this message translates to:
  /// **'Sternenrahmen'**
  String get effectStars;

  /// No description provided for @effectConfetti.
  ///
  /// In de, this message translates to:
  /// **'Konfetti'**
  String get effectConfetti;

  /// No description provided for @effectBurst.
  ///
  /// In de, this message translates to:
  /// **'Comicexplosion'**
  String get effectBurst;

  /// No description provided for @effectPirate.
  ///
  /// In de, this message translates to:
  /// **'Pirat'**
  String get effectPirate;

  /// No description provided for @effectAstronaut.
  ///
  /// In de, this message translates to:
  /// **'Astronaut'**
  String get effectAstronaut;

  /// No description provided for @effectRoyal.
  ///
  /// In de, this message translates to:
  /// **'Königlich'**
  String get effectRoyal;

  /// No description provided for @effectDiscoAlien.
  ///
  /// In de, this message translates to:
  /// **'Disco-Alien'**
  String get effectDiscoAlien;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
