import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'cutout.dart';
import 'cutout_page.dart';
import 'licenses_screen.dart';

Future<void> showPhotoPrivacy(BuildContext context) {
  final s = AppLocalizations.of(context);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => CutoutPage(
        title: s.privacyAndLicenses,
        children: [
          CutoutSurface(child: Text(s.photoPrivacy)),
          const SizedBox(height: 24),
          CutoutAction(
            style: CutoutActionStyle.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LicensesScreen()),
            ),
            child: Text(s.licenses),
          ),
        ],
      ),
    ),
  );
}
