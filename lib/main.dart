import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'data/word_catalog_loader.dart';
import 'game/game_session.dart';
import 'l10n/app_localizations.dart';
import 'ui/party_theme.dart';
import 'ui/session_screen.dart';
import 'ui/start_screen.dart';

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

class MyApp extends StatefulWidget {
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
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _session = GameSession();
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildPartyTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      home: StartScreen(
        buildSession: (_) => SessionScreen(
          session: _session,
          nameController: _name,
          catalogLoader: widget.catalogLoader ?? loadWordCatalog,
          now: widget.now,
          photoEditorLauncher: widget.photoEditorLauncher,
        ),
      ),
    );
  }
}
