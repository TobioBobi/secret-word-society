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
  /// **'1 Imposter · 2 Minuten'**
  String get roundSummary;

  /// No description provided for @startRound.
  ///
  /// In de, this message translates to:
  /// **'Runde starten'**
  String get startRound;

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
