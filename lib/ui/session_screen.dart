import 'package:flutter/material.dart';

import '../data/word_catalog_loader.dart';
import '../game/game_round.dart';
import '../game/game_session.dart';
import '../game/word_catalog.dart';
import '../l10n/app_localizations.dart';
import 'party_theme.dart';

typedef CatalogLoader = Future<WordCatalog> Function();

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, this.catalogLoader = loadWordCatalog});

  final CatalogLoader catalogLoader;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _session = GameSession();
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _headingFocus = FocusNode();
  final _scroll = ScrollController();
  NameProblem? _nameProblem;
  bool _starting = false;
  bool _catalogFailed = false;

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    _headingFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (_starting) return;
    setState(() {
      _nameProblem = _session.addPlayer(_name.text);
      if (_nameProblem == null) _name.clear();
    });
    _nameFocus.requestFocus();
  }

  Future<void> _startRound() async {
    if (_starting || !_session.canStart) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _starting = true;
      _catalogFailed = false;
    });
    try {
      final catalog = await widget.catalogLoader();
      if (!mounted) return;
      setState(() {
        _session.startRound(catalog);
        _name.clear();
        _nameProblem = null;
        _starting = false;
      });
      _focusNewPhase();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _catalogFailed = true;
      });
    }
  }

  void _returnToGroup() {
    setState(_session.returnToGroup);
    _focusNewPhase();
  }

  void _focusNewPhase() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _headingFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final round = _session.round;
    return PopScope(
      canPop: round == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _session.round != null) _returnToGroup();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final inset = constraints.maxWidth < 360 ? 16.0 : 24.0;
                  return CustomScrollView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(inset, 24, inset, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                strings.appTitle.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: PartyColors.lime,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                round == null
                                    ? strings.groupPhase
                                    : strings.handoffProgress(
                                        round.currentPlayerNumber!,
                                        round.players.length,
                                      ),
                                style: const TextStyle(
                                  color: PartyColors.muted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Focus(
                                focusNode: _headingFocus,
                                skipTraversal: true,
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    round == null
                                        ? strings.groupTitle
                                        : strings.handoffTitle(
                                            round.currentPlayer!.name,
                                          ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                round == null
                                    ? strings.groupIntro
                                    : strings.handoffIntro,
                                style: const TextStyle(
                                  color: PartyColors.muted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (round == null) _buildNameInput(strings),
                              if (round != null) _buildConcealedCard(strings),
                            ],
                          ),
                        ),
                      ),
                      if (round == null) _buildPlayers(strings, inset),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(inset, 24, inset, 24),
                        sliver: SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: round == null
                                ? _buildStartActions(strings)
                                : [
                                    OutlinedButton(
                                      onPressed: _returnToGroup,
                                      child: Text(
                                        strings.editGroup,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameInput(AppLocalizations strings) {
    final error = switch (_nameProblem) {
      NameProblem.empty => strings.nameEmpty,
      NameProblem.duplicate => strings.nameDuplicate,
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _name,
                focusNode: _nameFocus,
                enabled: !_starting,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: strings.nameLabel,
                  hintText: strings.nameHint,
                ),
                onSubmitted: (_) => _addPlayer(),
                onChanged: (_) {
                  if (_nameProblem != null) {
                    setState(() => _nameProblem = null);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: strings.addName,
              onPressed: _starting ? null : _addPlayer,
              style: IconButton.styleFrom(
                minimumSize: const Size(56, 56),
                backgroundColor: PartyColors.purple,
                foregroundColor: PartyColors.text,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: const TextStyle(color: PartyColors.coral),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Semantics(
          liveRegion: true,
          child: Text(
            strings.playerCount(_session.players.length),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        if (_session.players.isEmpty)
          Text(
            strings.emptyGroup,
            style: const TextStyle(color: PartyColors.muted),
          ),
      ],
    );
  }

  Widget _buildPlayers(AppLocalizations strings, double inset) {
    final players = _session.players;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: SliverList.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return Padding(
            key: ValueKey(player.id),
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: PartyColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: const TextStyle(color: PartyColors.muted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        player.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: strings.removePlayer(player.name),
                      onPressed: _starting
                          ? null
                          : () => setState(
                              () => _session.removePlayer(player.id),
                            ),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildStartActions(AppLocalizations strings) => [
    Text(
      _session.canStart
          ? strings.roundSummary
          : strings.playersMissing(
              GameRound.minimumPlayers - _session.players.length,
            ),
      textAlign: TextAlign.center,
      style: const TextStyle(color: PartyColors.muted),
    ),
    if (_catalogFailed)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Semantics(
          liveRegion: true,
          child: Text(
            strings.catalogFailed,
            style: const TextStyle(color: PartyColors.coral),
          ),
        ),
      ),
    const SizedBox(height: 12),
    FilledButton(
      onPressed: _session.canStart && !_starting ? _startRound : null,
      child: Text(
        _starting ? strings.startingRound : strings.startRound,
        textAlign: TextAlign.center,
      ),
    ),
  ];

  Widget _buildConcealedCard(AppLocalizations strings) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    decoration: BoxDecoration(
      color: PartyColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: PartyColors.outline, width: 2),
    ),
    child: Column(
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.lock_outline, size: 64, color: PartyColors.lime),
        ),
        const SizedBox(height: 20),
        Text(strings.secretConcealed, textAlign: TextAlign.center),
      ],
    ),
  );
}
