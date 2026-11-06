import 'package:flutter/material.dart';

import '../game/player_avatar.dart';
import '../l10n/app_localizations.dart';
import 'party_card.dart';
import 'party_theme.dart';
import 'player_avatar.dart';

class GameGuideScreen extends StatelessWidget {
  const GameGuideScreen({super.key});

  static const _first = PlayerAvatar(seed: 'guide-anna');
  static const _second = PlayerAvatar(seed: 'guide-ben');
  static const _imposter = PlayerAvatar(seed: 'guide-cleo');

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.gameGuide)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _Scene(
                  title: s.guideRevealTitle,
                  caption: s.guideReveal,
                  icon: Icons.visibility_off_outlined,
                  characters: [
                    _Character(
                      avatar: _first,
                      name: s.guideFirstPlayer,
                      label: s.guideGroupCard,
                      words: s.guideExampleWord,
                    ),
                    _Character(
                      avatar: _second,
                      name: s.guideSecondPlayer,
                      label: s.guideGroupCard,
                      words: s.guideExampleWord,
                    ),
                    _Character(
                      avatar: _imposter,
                      name: s.guideThirdPlayer,
                      label: s.guideImposterCard,
                      words: s.guideExampleHint,
                      accent: PartyColors.coral,
                    ),
                    const _PhoneHandoff(),
                  ],
                ),
                const SizedBox(height: 12),
                _Scene(
                  title: s.guideDiscussTitle,
                  caption: s.guideDiscuss,
                  icon: Icons.timer_outlined,
                  characters: [
                    _Character(
                      avatar: _first,
                      name: s.guideFirstPlayer,
                      words: s.guideCrunchy,
                    ),
                    _Character(
                      avatar: _second,
                      name: s.guideSecondPlayer,
                      words: s.guideSalty,
                    ),
                    _Character(
                      avatar: _imposter,
                      name: s.guideThirdPlayer,
                      words: s.guideMovieBreak,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Scene(
                  title: s.guideVoteTitle,
                  caption: s.guideVote,
                  icon: Icons.how_to_vote_outlined,
                  characters: [
                    _Character(avatar: _first, name: s.guideFirstPlayer),
                    _Character(avatar: _second, name: s.guideSecondPlayer),
                    _Character(
                      avatar: _imposter,
                      name: s.guideThirdPlayer,
                      words: s.guideMovieBreak,
                      accent: PartyColors.lime,
                      selected: true,
                    ),
                  ],
                  result: Column(
                    children: [
                      const Divider(height: 24),
                      Text(
                        s.guideResultWord,
                        style: theme.headlineSmall?.copyWith(
                          color: PartyColors.lime,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(s.guideResultRole, textAlign: TextAlign.center),
                      Text(
                        s.guideResultWin,
                        style: theme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class _Scene extends StatelessWidget {
  const _Scene({
    required this.title,
    required this.caption,
    required this.icon,
    required this.characters,
    this.result,
  });

  final String title;
  final String caption;
  final IconData icon;
  final List<Widget> characters;
  final Widget? result;

  @override
  Widget build(BuildContext context) => PartyCard(
    padding: const EdgeInsets.all(12),
    outlined: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: PartyColors.lime),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: characters,
        ),
        const SizedBox(height: 12),
        Text(caption),
        ?result,
      ],
    ),
  );
}

class _PhoneHandoff extends StatelessWidget {
  const _PhoneHandoff();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: double.infinity,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.arrow_forward_rounded, color: PartyColors.muted),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.phonelink_lock, color: PartyColors.lime),
        ),
        Icon(Icons.arrow_forward_rounded, color: PartyColors.muted),
      ],
    ),
  );
}

class _Character extends StatelessWidget {
  const _Character({
    required this.avatar,
    required this.name,
    this.words,
    this.label,
    this.accent = PartyColors.text,
    this.selected = false,
  });

  final PlayerAvatar avatar;
  final String name;
  final String? words;
  final String? label;
  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Semantics(
      label: name,
      container: true,
      selected: selected ? true : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PlayerAvatarView(avatar: avatar, size: 50),
              if (selected)
                const Positioned(
                  bottom: -2,
                  right: -4,
                  child: Icon(Icons.check_circle, color: PartyColors.lime),
                ),
            ],
          ),
          if (words != null) ...[
            if (label == null)
              Icon(Icons.arrow_drop_up, size: 16, color: accent)
            else
              const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null)
                      Text(
                        label!,
                        style: theme.labelSmall?.copyWith(
                          color: PartyColors.background,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    Text(
                      words!,
                      style: theme.labelLarge?.copyWith(
                        color: PartyColors.background,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
