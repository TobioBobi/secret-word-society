import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'game_guide_screen.dart';
import 'photo_privacy.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key, required this.buildSession});

  final WidgetBuilder buildSession;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  // Keep the top-right area free for language selection.
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/branding/start-logo.png',
                          semanticLabel: s.appTitle,
                          height: (MediaQuery.sizeOf(context).height * .32)
                              .clamp(96, 220),
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: buildSession),
                          ),
                          child: Text(s.play, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const GameGuideScreen(),
                            ),
                          ),
                          child: Text(s.gameGuide, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const _SettingsScreen(),
                            ),
                          ),
                          child: Text(s.settings, textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            OutlinedButton(
              onPressed: () => showPhotoPrivacy(context),
              child: Text(s.privacyAndLicenses, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
