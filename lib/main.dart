import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'ui/party_theme.dart';
import 'ui/session_screen.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Cutouts (DiceBear)',
    ], await rootBundle.loadString('assets/licenses/cutouts.txt'));
  });
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Photo capture and face detection (native)',
    ], await rootBundle.loadString('assets/licenses/photo-native.txt'));
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.catalogLoader,
    this.now = DateTime.now,
    this.photoEditorLauncher,
  });

  final CatalogLoader? catalogLoader;
  final DateTime Function() now;
  final PhotoEditorLauncher? photoEditorLauncher;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildPartyTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      home: catalogLoader == null
          ? SessionScreen(now: now, photoEditorLauncher: photoEditorLauncher)
          : SessionScreen(
              catalogLoader: catalogLoader!,
              now: now,
              photoEditorLauncher: photoEditorLauncher,
            ),
    );
  }
}
