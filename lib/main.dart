import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'ui/party_theme.dart';
import 'ui/session_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.catalogLoader});

  final CatalogLoader? catalogLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildPartyTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      home: catalogLoader == null
          ? const SessionScreen()
          : SessionScreen(catalogLoader: catalogLoader!),
    );
  }
}
