import 'dart:async';

import 'package:flutter/material.dart';

import '../data/word_catalog_loader.dart';
import '../game/game_round.dart';
import '../game/game_session.dart';
import '../game/player.dart';
import '../game/round_rules.dart';
import '../game/word_catalog.dart';
import '../l10n/app_localizations.dart';
import '../platform/round_signal.dart';
import 'party_card.dart';
import 'party_theme.dart';
import 'player_avatar.dart';
import 'secret_curtain.dart';
import 'time_up_card.dart';

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
  int _concealRevision = 0;
  Timer? _phaseTimer;
  final _roundSignal = RoundSignal();
  String? _signalToken;
  String? _revealToken;
  int _audioRevision = 0;
  bool _animateTimeUp = false;
  int _remainingSeconds = 0;
  int _revealSeconds = GameRound.revealDuration.inSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_roundSignal.cancel());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android can make the window visible in `inactive` before `resumed`.
    // Reconcile on every transition so that return frame is already current.
    if (state != AppLifecycleState.resumed) {
      _audioRevision++;
      _animateTimeUp = false;
      setState(() => _session.pauseReveal(widget.now()));
      _updateTimedPhase();
      _stopPhaseTimer();
      _concealSecret();
    } else {
      if (!_leavingDialog) {
        setState(() => _session.resumeReveal(widget.now()));
      }
      _updateTimedPhase();
      _startPhaseTimer();
    }
  }

  @override
  void dispose() {
    unawaited(_roundSignal.cancel());
    _stopPhaseTimer();
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

  Future<void> _renamePlayer(Player player) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(text: player.name);
    NameProblem? problem;
    final route = DialogRoute<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          scrollable: true,
          title: Text(strings.renamePlayer),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: strings.nameLabel,
              errorText: problem == null
                  ? null
                  : (problem == NameProblem.empty
                        ? strings.nameEmpty
                        : strings.nameDuplicate),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.cancelEdit),
            ),
            FilledButton(
              onPressed: () {
                final result = _session.renamePlayer(
                  player.id,
                  controller.text,
                );
                if (result != null) {
                  updateDialog(() => problem = result);
                } else {
                  setState(() {});
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(strings.saveName),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    controller.dispose();
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
    _cancelSignal();
    _stopPhaseTimer();
    setState(_session.returnToGroup);
    _focusNewPhase();
  }

  void _concealSecret() {
    setState(() {
      _concealRevision++;
      _session.concealSecret();
    });
  }

  void _peekCard(
    GameRound expected,
    bool reveal,
    int expectedRevision, {
    bool fullyOpen = false,
  }) {
    if (expectedRevision != _concealRevision) return;
    final current = _session.round;
    // Preparing, fully opening and releasing can all precede the next frame.
    // Completion and concealment must still apply only to the same person.
    if (current != null &&
        identical(current.players, expected.players) &&
        identical(current.currentPlayer, expected.currentPlayer) &&
        _canAct(current)) {
      if (!reveal) {
        setState(_session.concealSecret);
        return;
      }
      if (fullyOpen && current.phase == GamePhase.secret) {
        setState(_session.markSecretViewed);
        return;
      }
    }
    if (!_canAct(expected)) return;
    if (reveal && expected.phase == GamePhase.handoff) {
      setState(() => _session.revealSecret(markAsViewed: fullyOpen));
    }
  }

  void _advanceCard(GameRound expected) {
    // Ignore stale callbacks, rapid repeated taps and actions while interrupted.
    if (!_canAct(expected) || !expected.canAdvanceCard) return;
    setState(_session.hideAndAdvance);
    _focusNewPhase();
  }

  void _startDiscussion(GameRound expected) {
    if (!_canAct(expected) || expected.phase != GamePhase.ready) {
      return;
    }
    setState(() {
      _session.startDiscussion(widget.now());
      _remainingSeconds = _session.round!.discussionDuration.inSeconds;
    });
    _signalToken = '${DateTime.now().microsecondsSinceEpoch}';
    unawaited(
      _roundSignal.arm(_signalToken!, _session.round!.discussionEndsAt!),
    );
    _startPhaseTimer();
    _focusNewPhase();
  }

  bool _canAct(GameRound expected) {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return mounted &&
        identical(_session.round, expected) &&
        !_leavingDialog &&
        (lifecycle == null || lifecycle == AppLifecycleState.resumed);
  }

  void _selectSuspect(GameRound expected, String? playerId) {
    if (!_canAct(expected) ||
        expected.phase != GamePhase.voting ||
        playerId == null) {
      return;
    }
    setState(() => _session.selectSuspect(playerId));
  }

  void _confirmSuspect(GameRound expected) {
    if (!_canAct(expected) ||
        expected.phase != GamePhase.voting ||
        expected.suspects.isEmpty) {
      return;
    }
    _cancelSignal();
    setState(() {
      _session.confirmSuspect(widget.now());
      _revealSeconds = GameRound.revealDuration.inSeconds;
    });
    _revealToken = '${DateTime.now().microsecondsSinceEpoch}';
    unawaited(_roundSignal.prepareReveal(_revealToken!));
    _startPhaseTimer();
    _focusNewPhase();
  }

  void _newRound(GameRound expected) {
    if (!_canAct(expected) || expected.phase != GamePhase.result) return;
    _cancelSignal();
    _stopPhaseTimer();
    setState(() {
      _session.newRound();
      _remainingSeconds = _session.round!.discussionDuration.inSeconds;
    });
    _focusNewPhase();
  }

  void _startPhaseTimer() {
    _stopPhaseTimer();
    final phase = _session.round?.phase;
    if (phase != GamePhase.discussion && phase != GamePhase.reveal) return;
    if (phase == GamePhase.reveal && _session.round!.revealEndsAt == null) {
      return;
    }
    _phaseTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _updateTimedPhase(),
    );
  }

  void _stopPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
  }

  void _cancelSignal() {
    _signalToken = null;
    _revealToken = null;
    _animateTimeUp = false;
    unawaited(_roundSignal.cancel());
  }

  void _updateTimedPhase() {
    final round = _session.round;
    if (round?.phase == GamePhase.reveal) {
      if (round!.revealEndsAt == null) return;
      final now = widget.now();
      final seconds =
          (round.remainingRevealTime(now).inMicroseconds /
                  Duration.microsecondsPerSecond)
              .ceil();
      if (seconds == _revealSeconds && seconds > 0) return;
      setState(() {
        _session.advanceTime(now);
        _revealSeconds = seconds;
      });
      if (_session.round!.phase == GamePhase.result) {
        _stopPhaseTimer();
        _focusNewPhase();
        final resultRound = _session.round!;
        final token = _revealToken;
        final revision = _audioRevision;
        _revealToken = null; // Consume before scheduling the reveal frame.
        final recent =
            now.difference(round.revealEndsAt!) <= const Duration(seconds: 2);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (token == null || !mounted) return;
          unawaited(
            _roundSignal.reveal(
              token,
              resultRound.result!.winner.name,
              audible:
                  recent && revision == _audioRevision && _canAct(resultRound),
            ),
          );
        });
      }
      return;
    }
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
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      final visible =
          lifecycle == null || lifecycle == AppLifecycleState.resumed;
      final recent =
          now.difference(round.discussionEndsAt!) <= const Duration(seconds: 2);
      _animateTimeUp = visible && !_leavingDialog && recent;
      if (_signalToken != null) {
        unawaited(
          _roundSignal.finish(_signalToken!, audible: visible && recent),
        );
      }
      _stopPhaseTimer();
      if (!_leavingDialog) _focusNewPhase();
    }
  }

  Future<void> _confirmLeaveRound() async {
    if (_leavingDialog || _session.round == null) return;
    if (_session.round!.phase == GamePhase.result) {
      _returnToGroup();
      return;
    }
    _leavingDialog = true;
    setState(() => _session.pauseReveal(widget.now()));
    if (_session.round!.phase == GamePhase.reveal) _stopPhaseTimer();
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
            style: TextButton.styleFrom(foregroundColor: PartyColors.coral),
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
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
        setState(() => _session.resumeReveal(widget.now()));
        _startPhaseTimer();
      }
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
    final concealRevision = _concealRevision;
    final round = _session.round;
    final result = round?.result;
    final compactReveal =
        (round?.phase == GamePhase.reveal ||
            round?.phase == GamePhase.voting) &&
        (MediaQuery.sizeOf(context).height < 650 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3);
    final groupWon = result?.winner == Winner.group;
    final revealed = round?.phase == GamePhase.secret;
    final title = switch (round?.phase) {
      null => strings.groupTitle,
      GamePhase.handoff => strings.handoffTitle(round!.currentPlayer!.name),
      GamePhase.secret => strings.handoffTitle(round!.currentPlayer!.name),
      GamePhase.ready => strings.readyTitle,
      GamePhase.discussion => strings.discussionTitle,
      GamePhase.voting => strings.votingTitle,
      GamePhase.reveal => strings.revealTitle,
      GamePhase.result =>
        groupWon ? strings.groupWinTitle : strings.imposterWinTitle,
    };
    final phaseLabel = switch (round?.phase) {
      null => strings.groupPhase,
      GamePhase.handoff || GamePhase.secret => strings.handoffProgress(
        round!.currentPlayerNumber!,
        round.players.length,
      ),
      GamePhase.ready => strings.readyPhase,
      GamePhase.discussion => strings.discussionPhase,
      GamePhase.voting => strings.votingPhase,
      GamePhase.reveal => strings.revealPhase,
      GamePhase.result => strings.resultPhase,
    };
    final phaseIcon = switch (round?.phase) {
      null => Icons.groups_outlined,
      GamePhase.handoff || GamePhase.secret => Icons.phone_android_outlined,
      GamePhase.ready => Icons.check_circle_outline,
      GamePhase.discussion => Icons.timer_outlined,
      GamePhase.voting => Icons.how_to_vote_outlined,
      GamePhase.reveal => Icons.hourglass_bottom_outlined,
      GamePhase.result => Icons.celebration_outlined,
    };
    final intro = switch (round?.phase) {
      null => strings.groupIntro,
      GamePhase.handoff => strings.handoffIntro,
      GamePhase.secret => strings.privateIntro,
      GamePhase.ready || GamePhase.discussion => strings.readyIntro,
      GamePhase.voting =>
        round!.allowsMultipleSuspects
            ? strings.multipleVotingIntro
            : strings.votingIntro,
      GamePhase.reveal => strings.revealIntro,
      GamePhase.result =>
        groupWon
            ? strings.groupWinIntro(result!.imposters.length)
            : strings.imposterWinIntro(result!.imposters.length),
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
                  if (round?.currentPlayer != null) {
                    return CustomScrollView(
                      controller: _scroll,
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  12,
                                  24,
                                  8,
                                ),
                                child: _buildPhaseLabel(phaseLabel, phaseIcon),
                              ),
                              Expanded(
                                child: SizedBox(
                                  // Gives the sliver an intrinsic minimum without
                                  // asking the curtain's LayoutBuilder to measure.
                                  height: 420,
                                  child: SecretCurtain(
                                    key: ValueKey(round!.currentPlayer!.id),
                                    title: title,
                                    name: round.currentPlayer!.name,
                                    avatar: PlayerAvatarView(
                                      avatar: round.currentPlayer!.avatar,
                                      size: 182,
                                    ),
                                    advanceAction: FilledButton(
                                      onPressed: () => _advanceCard(round),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: PartyColors.surface,
                                        foregroundColor: PartyColors.text,
                                        side: const BorderSide(
                                          color: PartyColors.outline,
                                        ),
                                      ),
                                      child: Text(
                                        strings.nextPlayer,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    headingFocus: _headingFocus,
                                    revealed: revealed,
                                    concealRevision: concealRevision,
                                    onReveal: (fullyOpen) => _peekCard(
                                      round,
                                      true,
                                      concealRevision,
                                      fullyOpen: fullyOpen,
                                    ),
                                    onConceal: () => _peekCard(
                                      round,
                                      false,
                                      concealRevision,
                                    ),
                                    secretBuilder: (_) => _buildSecretContent(
                                      strings,
                                      round.currentSecret!,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  final scrollView = CustomScrollView(
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
                              if (!compactReveal) ...[
                                Row(
                                  children: [
                                    const ExcludeSemantics(
                                      child: Icon(
                                        Icons.auto_awesome_outlined,
                                        size: 24,
                                        color: PartyColors.lime,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        strings.appTitle.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                          color: PartyColors.lime,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildPhaseLabel(phaseLabel, phaseIcon),
                              ],
                              if (round?.currentPlayerNumber != null) ...[
                                const SizedBox(height: 12),
                                ExcludeSemantics(
                                  child: LinearProgressIndicator(
                                    value:
                                        (round!.currentPlayerNumber! - 1) /
                                        round.players.length,
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(4),
                                    color: PartyColors.lime,
                                    backgroundColor: PartyColors.surface,
                                  ),
                                ),
                              ],
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
                                    style: compactReveal
                                        ? const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                          )
                                        : Theme.of(context)
                                              .textTheme
                                              .headlineLarge,
                                  ),
                                ),
                              ),
                              if (!compactReveal) ...[
                                const SizedBox(height: 16),
                                Text(
                                  intro,
                                  style: const TextStyle(
                                    color: PartyColors.muted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              if (round == null) _buildNameInput(strings),
                              if (round != null)
                                if (round.phase == GamePhase.ready)
                                  _buildReadyCard(strings)
                                else if (round.phase == GamePhase.discussion)
                                  _buildCountdown(strings)
                                else if (round.phase == GamePhase.voting)
                                  _buildVotingCard(strings)
                                else if (round.phase == GamePhase.reveal)
                                  _buildRevealCountdown(strings)
                                else if (result != null)
                                  _buildResult(strings, result),
                            ],
                          ),
                        ),
                      ),
                      if (round == null) _buildPlayers(strings, inset),
                      if (round?.phase == GamePhase.voting)
                        _buildSuspects(round!, inset),
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
                  return round?.phase == GamePhase.voting &&
                          !round!.allowsMultipleSuspects
                      ? RadioGroup<String>(
                          groupValue: round.suspects.firstOrNull?.id,
                          onChanged: (id) => _selectSuspect(round, id),
                          child: scrollView,
                        )
                      : scrollView;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseLabel(String label, IconData icon) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PartyColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 20, color: PartyColors.lime),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: PartyColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildNameInput(AppLocalizations strings) {
    final error = switch (_nameProblem) {
      NameProblem.empty => strings.nameEmpty,
      NameProblem.duplicate => strings.nameDuplicate,
      NameProblem.groupFull => strings.groupFull,
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
                enabled:
                    !_starting &&
                    _session.players.length < RoundRules.maximumPlayers,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                // Android keyboards need suggestions for gesture typing.
                enableSuggestions: true,
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
              onPressed:
                  _starting ||
                      _session.players.length >= RoundRules.maximumPlayers
                  ? null
                  : _addPlayer,
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
        if (_session.players.length == RoundRules.maximumPlayers)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(strings.groupFull),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (round.phase == GamePhase.voting) ...[
          FilledButton(
            onPressed: round.suspects.isEmpty
                ? null
                : () => _confirmSuspect(round),
            child: Text(
              round.suspects.isEmpty
                  ? strings.selectSuspect
                  : (round.suspects.length == 1
                        ? strings.confirmSuspect(round.suspects.single.name)
                        : strings.confirmSuspects(round.suspects.length)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (round.phase == GamePhase.result) ...[
          FilledButton(
            onPressed: () => _newRound(round),
            child: Text(strings.nextRound, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              if (_canAct(round)) _returnToGroup();
            },
            child: Text(strings.editGroup, textAlign: TextAlign.center),
          ),
        ],
        if (round.phase == GamePhase.ready) ...[
          _buildDurationPicker(strings),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _startDiscussion(round),
            child: Text(
              strings.startDiscussion(
                _formatTime(round.discussionDuration.inSeconds),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSuspects(GameRound round, double inset) => SliverPadding(
    padding: EdgeInsets.fromLTRB(inset, 16, inset, 0),
    sliver: SliverList.builder(
      itemCount: round.players.length,
      itemBuilder: (context, index) {
        final player = round.players[index];
        final selected = round.suspects.any(
          (suspect) => suspect.id == player.id,
        );
        return Padding(
          key: ValueKey(player.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: round.allowsMultipleSuspects
              ? CheckboxListTile(
                  value: selected,
                  onChanged: round.canSelectSuspect(player.id)
                      ? (_) => _selectSuspect(round, player.id)
                      : null,
                  title: Text(player.name),
                  secondary: PlayerAvatarView(avatar: player.avatar),
                  activeColor: PartyColors.lime,
                  checkColor: PartyColors.background,
                  selected: selected,
                  tileColor: PartyColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: selected ? PartyColors.lime : PartyColors.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                )
              : RadioListTile<String>(
                  value: player.id,
                  title: Text(player.name),
                  secondary: PlayerAvatarView(avatar: player.avatar),
                  selected: selected,
                  activeColor: PartyColors.lime,
                  tileColor: PartyColors.surface,
                  selectedTileColor: PartyColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: selected ? PartyColors.lime : PartyColors.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                ),
        );
      },
    ),
  );

  Widget _buildResult(AppLocalizations strings, RoundResult result) {
    final groupWon = result.winner == Winner.group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartyCard(
          color: groupWon ? PartyColors.lime : PartyColors.coral,
          foregroundColor: PartyColors.background,
          outlined: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    groupWon
                        ? Icons.emoji_events_outlined
                        : Icons.theater_comedy_outlined,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                groupWon
                    ? strings.groupWins
                    : strings.imposterWins(result.imposters.length),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PartyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, (label, value)) in [
                (strings.resultSuspect, result.suspects),
                (
                  strings.resultImposter(result.imposters.length),
                  result.imposters,
                ),
                (strings.resultWord, <Player>[]),
              ].indexed)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 20),
                  child: Semantics(
                    // Keep each label with its value when reading the result.
                    container: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(color: PartyColors.muted),
                        ),
                        const SizedBox(height: 4),
                        if (index < 2)
                          for (final player in value)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  PlayerAvatarView(
                                    avatar: player.avatar,
                                    size: 64,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                        else
                          Text(
                            result.word,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerAvatarView(avatar: player.avatar),
                        IconButton(
                          key: ValueKey('reroll-${player.id}'),
                          tooltip: strings.rerollAvatar(player.name),
                          onPressed: _starting
                              ? null
                              : () => setState(
                                  () => _session.rerollAvatar(player.id),
                                ),
                          icon: const Icon(Icons.casino_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: _starting
                            ? null
                            : () => _renamePlayer(player),
                        child: Text(player.name, textAlign: TextAlign.center),
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

  String _formatTime(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  String _imposterRange(int count) {
    final minimum = RoundRules.minimumImposters(count);
    final maximum = RoundRules.maximumImposters(count);
    return minimum == maximum ? '$minimum' : '$minimum–$maximum';
  }

  void _setDiscussionDuration(Duration? duration) {
    if (_starting ||
        (_session.round != null && _session.round!.phase != GamePhase.ready)) {
      return;
    }
    setState(() => _session.setDiscussionDuration(duration));
  }

  Widget _buildDurationPicker(AppLocalizations strings) {
    final duration = _session.discussionDuration;
    final width = MediaQuery.sizeOf(context).width.clamp(0.0, 560.0);
    final inset = width < 360 ? 16.0 : 24.0;
    final stacked =
        MediaQuery.textScalerOf(context).scale(28) * 5 + 112 >
        width - inset * 2 - 32;
    final value = Semantics(
      liveRegion: true,
      label: strings.selectedDuration(_formatTime(duration.inSeconds)),
      excludeSemantics: true,
      child: Text(
        _formatTime(duration.inSeconds),
        key: const ValueKey('round-duration'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
    Widget stepButton({required bool increase}) {
      final enabled =
          !_starting &&
          (increase
              ? duration < RoundRules.maximumDuration
              : duration > RoundRules.minimumDuration);
      return IconButton.outlined(
        tooltip: increase ? strings.extendDuration : strings.shortenDuration,
        onPressed: enabled
            ? () => _setDiscussionDuration(
                increase
                    ? duration + RoundRules.durationStep
                    : duration - RoundRules.durationStep,
              )
            : null,
        icon: Icon(increase ? Icons.add : Icons.remove),
      );
    }

    return PartyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.roundDuration, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Column(
            children: [
              if (stacked) value,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  stepButton(increase: false),
                  if (!stacked) Expanded(child: value),
                  stepButton(increase: true),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: !_starting && _session.hasManualDuration
                ? () => _setDiscussionDuration(null)
                : null,
            icon: const Icon(Icons.restart_alt),
            label: Text(strings.automaticDuration),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStartActions(AppLocalizations strings) => [
    Text(
      _session.canStart
          ? strings.roundSummary(
              _imposterRange(_session.players.length),
              _formatTime(_session.discussionDuration.inSeconds),
            )
          : strings.playersMissing(
              GameRound.minimumPlayers - _session.players.length,
            ),
      textAlign: TextAlign.center,
      style: const TextStyle(color: PartyColors.muted),
    ),
    if (_session.canStart) ...[
      const SizedBox(height: 12),
      _buildDurationPicker(strings),
    ],
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

  Widget _buildSecretContent(AppLocalizations strings, PlayerSecret secret) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (secret.role == PlayerRole.imposter) ...[
            Text(
              _session.round!.allowsMultipleSuspects
                  ? strings.multipleImposterRole
                  : strings.imposterRole,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
        ],
      );

  Widget _buildReadyCard(AppLocalizations strings) =>
      _buildStatusCard(strings.readyCard, Icons.check_circle_outline);

  Widget _buildCountdown(AppLocalizations strings) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return PartyCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      color: PartyColors.purple,
      outlined: false,
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

  Widget _buildVotingCard(AppLocalizations strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TimeUpCard(
        animate: _animateTimeUp,
        multipleSuspects: _session.round!.allowsMultipleSuspects,
      ),
      if (MediaQuery.sizeOf(context).height < 650 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) ...[
        const SizedBox(height: 16),
        Text(
          _session.round!.allowsMultipleSuspects
              ? strings.multipleVotingIntro
              : strings.votingIntro,
          style: const TextStyle(color: PartyColors.muted),
        ),
      ],
    ],
  );

  Widget _buildRevealCountdown(AppLocalizations strings) => PartyCard(
    color: PartyColors.purple,
    outlined: false,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Semantics(
      liveRegion: true,
      label: strings.revealRemaining(_revealSeconds),
      excludeSemantics: true,
      child: SizedBox(
        height: (MediaQuery.sizeOf(context).height * 0.25).clamp(80.0, 200.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$_revealSeconds',
            style: const TextStyle(fontSize: 112, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    ),
  );

  Widget _buildStatusCard(String label, IconData icon) => PartyCard(
    padding: const EdgeInsets.all(20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 32, color: PartyColors.lime)),
        const SizedBox(width: 16),
        Expanded(child: Text(label)),
      ],
    ),
  );
}
