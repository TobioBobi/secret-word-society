import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'cutout.dart';
import 'cutout_page.dart';
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
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: PaperConfetti(),
                        ),
                        const SizedBox(height: Cutout.gap),
                        Image.asset(
                          'assets/branding/start-logo.png',
                          semanticLabel: s.appTitle,
                          height: (MediaQuery.sizeOf(context).height * .32)
                              .clamp(128, 240),
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 32),
                        CutoutAction(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: buildSession),
                          ),
                          child: Text(s.play, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: Cutout.gap),
                        CutoutAction(
                          style: CutoutActionStyle.secondary,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const GameGuideScreen(),
                            ),
                          ),
                          child: Text(s.gameGuide, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: Cutout.gap),
                        CutoutAction(
                          style: CutoutActionStyle.outlined,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const _SettingsScreen(),
                            ),
                          ),
                          child: Text(s.settings, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: PaperConfetti(),
                          ),
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
    return CutoutPage(
      title: s.settings,
      children: [
        CutoutAction(
          style: CutoutActionStyle.outlined,
          onPressed: () => showPhotoPrivacy(context),
          child: Text(s.privacyAndLicenses, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
