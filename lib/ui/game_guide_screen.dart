import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'party_card.dart';

class GameGuideScreen extends StatelessWidget {
  const GameGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.gameGuide)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _GuideHeading(s.guideRevealTitle),
                Text(s.guideReveal),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ExampleCard(
                      label: s.guideGroupCard,
                      value: s.guideExampleWord,
                    ),
                    _ExampleCard(
                      label: s.guideImposterCard,
                      value: s.guideExampleHint,
                    ),
                  ],
                ),
                _GuideHeading(s.guideDiscussTitle),
                Text(s.guideDiscuss),
                const SizedBox(height: 8),
                Text(s.guideSkip),
                _GuideHeading(s.guideVoteTitle),
                Text(s.guideVote),
                _GuideHeading(s.guideResultTitle),
                Text(s.guideResult),
                const SizedBox(height: 8),
                Text(s.guideExampleResult),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideHeading extends StatelessWidget {
  const _GuideHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => PartyCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
