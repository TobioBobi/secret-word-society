import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

Future<void> showPhotoPrivacy(BuildContext context) {
  final s = AppLocalizations.of(context);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(s.privacyAndLicenses)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(s.photoPrivacy),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => showLicensePage(context: context),
                child: Text(s.licenses),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
