import 'dart:async';

import 'package:flutter/material.dart';

import '../data/word_catalog_loader.dart';
import '../game/game_round.dart';
import '../game/game_session.dart';
import '../game/word_catalog.dart';
import '../l10n/app_localizations.dart';
import 'party_theme.dart';

typedef CatalogLoader = Future<WordCatalog> Function();

class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    this.catalogLoader = loadWordCatalog,
    this.now = DateTime.now,
  });

  final CatalogLoader catalogLoader;
  // The production clock also counts time when Flutter suspends frames.
  final DateTime Function() now;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with WidgetsBindingObserver {
  final _session = GameSession();
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _headingFocus = FocusNode();
  final _scroll = ScrollController();
  NameProblem? _nameProblem;
  bool _starting = false;
  bool _catalogFailed = false;
  bool _leavingDialog = false;
  Timer? _discussionTimer;
  int _remainingSeconds = GameRound.discussionDuration.inSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android can make the window visible in `inactive` before `resumed`.
    // Reconcile on every transition so that return frame is already current.
    _updateDiscussion();
    if (state != AppLifecycleState.resumed) {
      _stopDiscussionTimer();
      _concealSecret();
    } else {
      _startDiscussionTimer();
    }
  }

  @override
  void dispose() {
    _stopDiscussionTimer();
    WidgetsBinding.instance.removeObserver(this);
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
    _stopDiscussionTimer();
    setState(_session.returnToGroup);
    _focusNewPhase();
  }

  void _concealSecret() {
    if (_session.round?.phase != GamePhase.secret) return;
    setState(_session.concealSecret);
    _focusNewPhase();
  }

  void _actOnCard(GameRound expected, {required bool reveal}) {
    // Ignore stale callbacks, rapid repeated taps and actions while interrupted.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!identical(_session.round, expected) ||
        _leavingDialog ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    setState(reveal ? _session.revealSecret : _session.hideAndAdvance);
    _focusNewPhase();
  }

  void _startDiscussion(GameRound expected) {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!identical(_session.round, expected) ||
        expected.phase != GamePhase.ready ||
        _leavingDialog ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    setState(() {
      _session.startDiscussion(widget.now());
      _remainingSeconds = GameRound.discussionDuration.inSeconds;
    });
    _startDiscussionTimer();
    _focusNewPhase();
  }

  void _startDiscussionTimer() {
    _stopDiscussionTimer();
    if (_session.round?.phase != GamePhase.discussion) return;
    _discussionTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _updateDiscussion(),
    );
  }

  void _stopDiscussionTimer() {
    _discussionTimer?.cancel();
    _discussionTimer = null;
  }

  void _updateDiscussion() {
    final round = _session.round;
    if (round?.phase != GamePhase.discussion) return;
    final now = widget.now();
    final seconds =
        (round!.remainingDiscussionTime(now).inMicroseconds /
                Duration.microsecondsPerSecond)
            .ceil();
    if (seconds == _remainingSeconds && now.isBefore(round.discussionEndsAt!)) {
      return;
    }
    setState(() {
      _session.advanceTime(now);
      _remainingSeconds = seconds;
    });
    if (_session.round!.phase == GamePhase.voting) {
      _stopDiscussionTimer();
      if (!_leavingDialog) _focusNewPhase();
    }
  }

  Future<void> _confirmLeaveRound() async {
    if (_leavingDialog || _session.round == null) return;
    _leavingDialog = true;
    _concealSecret();
    // Remove the secret from both rendering and semantics before opening a route.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(strings.leaveRoundTitle),
        content: Text(strings.leaveRoundBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.keepPlaying),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.leaveRound),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _leavingDialog = false;
    if (leave == true) {
      _returnToGroup();
    } else {
      _focusNewPhase();
    }
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
    final revealed = round?.phase == GamePhase.secret;
    final title = switch (round?.phase) {
      null => strings.groupTitle,
      GamePhase.handoff => strings.handoffTitle(round!.currentPlayer!.name),
      GamePhase.secret => strings.privateTitle(round!.currentPlayer!.name),
      GamePhase.ready => strings.readyTitle,
      GamePhase.discussion => strings.discussionTitle,
      GamePhase.voting || GamePhase.result => strings.votingTitle,
    };
    final phaseLabel = switch (round?.phase) {
      null => strings.groupPhase,
      GamePhase.handoff || GamePhase.secret => strings.handoffProgress(
        round!.currentPlayerNumber!,
        round.players.length,
      ),
      GamePhase.ready => strings.readyPhase,
      GamePhase.discussion => strings.discussionPhase,
      GamePhase.voting || GamePhase.result => strings.votingPhase,
    };
    final intro = switch (round?.phase) {
      null => strings.groupIntro,
      GamePhase.handoff => strings.handoffIntro,
      GamePhase.secret => strings.privateIntro,
      GamePhase.ready || GamePhase.discussion => strings.readyIntro,
      GamePhase.voting || GamePhase.result => strings.votingIntro,
    };
    return PopScope(
      canPop: round == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeaveRound();
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
                                phaseLabel,
                                style: const TextStyle(
                                  color: PartyColors.muted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Focus(
                                key: ValueKey(
                                  '${round?.phase}-${round?.currentPlayerNumber}',
                                ),
                                focusNode: _headingFocus,
                                skipTraversal: true,
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                intro,
                                style: const TextStyle(
                                  color: PartyColors.muted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (round == null) _buildNameInput(strings),
                              if (round != null)
                                if (round.phase == GamePhase.ready)
                                  _buildReadyCard(strings)
                                else if (round.phase == GamePhase.discussion)
                                  _buildCountdown(strings)
                                else if (round.phase == GamePhase.voting)
                                  _buildVotingCard(strings)
                                else if (revealed)
                                  _buildSecretCard(
                                    strings,
                                    round.currentSecret!,
                                  )
                                else
                                  _buildConcealedCard(strings),
                            ],
                          ),
                        ),
                      ),
                      if (round == null) _buildPlayers(strings, inset),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(inset, 24, inset, 24),
                        sliver: round == null
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: _buildStartActions(strings),
                                ),
                              )
                            : SliverToBoxAdapter(
                                child: _buildRoundActions(strings, round),
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

  Widget _buildRoundActions(AppLocalizations strings, GameRound round) {
    final revealed = round.phase == GamePhase.secret;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (round.phase == GamePhase.ready) ...[
          FilledButton(
            onPressed: () => _startDiscussion(round),
            child: Text(strings.startDiscussion, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
        ],
        if (round.phase == GamePhase.handoff || revealed) ...[
          FilledButton(
            key: ValueKey(round.phase),
            onPressed: () => _actOnCard(round, reveal: !revealed),
            child: Text(
              !revealed
                  ? strings.revealSecret
                  : round.currentPlayerNumber == round.players.length
                  ? strings.hideAndFinish
                  : strings.hideAndPass,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: _confirmLeaveRound,
          child: Text(strings.editGroup, textAlign: TextAlign.center),
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

  Widget _buildSecretCard(AppLocalizations strings, PlayerSecret secret) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PartyColors.purple,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (secret.role == PlayerRole.imposter) ...[
              Text(
                strings.imposterRole,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              secret.role == PlayerRole.imposter
                  ? strings.secretHint
                  : strings.secretWord,
            ),
            const SizedBox(height: 12),
            Text(
              secret.text,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );

  Widget _buildReadyCard(AppLocalizations strings) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: PartyColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: PartyColors.outline, width: 2),
    ),
    child: Column(
      children: [
        const ExcludeSemantics(
          child: Icon(
            Icons.check_circle_outline,
            size: 64,
            color: PartyColors.lime,
          ),
        ),
        const SizedBox(height: 20),
        Text(strings.readyCard, textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildCountdown(AppLocalizations strings) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        color: PartyColors.purple,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Semantics(
        // Available on exploration, without a live announcement every second.
        label: strings.discussionRemaining(_remainingSeconds),
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$minutes:$seconds',
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVotingCard(AppLocalizations strings) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: PartyColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: PartyColors.outline, width: 2),
    ),
    child: Column(
      children: [
        const ExcludeSemantics(
          child: Icon(
            Icons.how_to_vote_outlined,
            size: 64,
            color: PartyColors.lime,
          ),
        ),
        const SizedBox(height: 20),
        Text(strings.votingCard, textAlign: TextAlign.center),
      ],
    ),
  );
}
