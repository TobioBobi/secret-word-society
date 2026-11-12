import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/game/game_round.dart';
import 'package:secret_word_society/game/round_rules.dart';

import '../widget_test.dart' show multiHintCatalog;

void main() {
  final now = DateTime.utc(2026, 11, 1);
  GameSession session() {
    final game = GameSession();
    for (final name in ['Anna', 'Ben', 'Cem']) {
      game.addPlayer(name);
    }
    return game;
  }

  void distribute(GameSession game) {
    while (game.round!.currentPlayer != null) {
      game.revealSecret();
      game.hideAndAdvance();
    }
  }

  test('automatic duration is 15 seconds per person', () {
    for (final (count, seconds) in [(3, 45), (4, 60), (14, 210)]) {
      final game = session();
      for (var index = 3; index < count; index++) {
        game.addPlayer('Person $index');
      }
      expect(game.discussionDuration, Duration(seconds: seconds));
      game.startRound(multiHintCatalog);
      distribute(game);
      game.startDiscussion(now);
      expect(game.round!.discussionEndsAt, now.add(Duration(seconds: seconds)));
    }
  });

  test('automatic duration follows group edits until manually overridden', () {
    final game = session();
    expect(game.discussionDuration, const Duration(seconds: 45));
    game.addPlayer('Dana');
    expect(game.discussionDuration, const Duration(minutes: 1));
    game.setDiscussionDuration(const Duration(seconds: 105));
    game.addPlayer('Emil');
    expect(game.discussionDuration, const Duration(seconds: 105));
    game.setDiscussionDuration(null);
    expect(game.hasManualDuration, isFalse);
    expect(game.discussionDuration, const Duration(seconds: 75));
    game.removePlayer(game.players.last.id);
    expect(game.discussionDuration, const Duration(minutes: 1));
    final coldSession = session();
    expect(coldSession.hasManualDuration, isFalse);
    expect(coldSession.discussionDuration, const Duration(seconds: 45));
  });

  test('reject invalid choices before consuming a word or changing state', () {
    final game = session();
    for (final duration in [
      Duration.zero,
      const Duration(seconds: -30),
      const Duration(seconds: 15),
      const Duration(seconds: 31),
      const Duration(microseconds: 30000001),
      const Duration(seconds: 915),
    ]) {
      expect(() => game.setDiscussionDuration(duration), throwsArgumentError);
      expect(game.hasManualDuration, isFalse);
      expect(
        () => GameRound.start(
          players: game.players,
          catalog: multiHintCatalog,
          discussionDuration: duration,
        ),
        throwsArgumentError,
      );
    }
    for (final duration in [
      RoundRules.minimumDuration,
      const Duration(seconds: 45),
      const Duration(seconds: 75),
      RoundRules.maximumDuration,
    ]) {
      game.setDiscussionDuration(duration);
      game.startRound(multiHintCatalog);
      expect(game.round!.discussionDuration, duration);
      game.returnToGroup();
    }
  });

  test('ready edits freeze at start, exact deadline survives interruption and follow-up', () {
    final game = session();
    game.setDiscussionDuration(const Duration(minutes: 15));
    game.startRound(multiHintCatalog);
    expect(
      () => game.setDiscussionDuration(const Duration(minutes: 1)),
      throwsStateError,
    );
    distribute(game);
    game.setDiscussionDuration(const Duration(seconds: 75));
    final ready = game.round!;
    game.startDiscussion(now);
    final running = game.round!;
    expect(running.discussionEndsAt, now.add(const Duration(seconds: 75)));
    expect(() => game.setDiscussionDuration(null), throwsStateError);
    expect(
      () => running.withDiscussionDuration(const Duration(minutes: 1)),
      throwsStateError,
    );
    expect(ready.discussionDuration, const Duration(seconds: 75));
    game.advanceTime(now.add(const Duration(seconds: 74)));
    expect(
      game.round!.remainingDiscussionTime(now.add(const Duration(seconds: 74))),
      const Duration(seconds: 1),
    );
    game.advanceTime(now.add(const Duration(seconds: 75)));
    expect(game.round!.phase, GamePhase.voting);
    game.selectSuspect(game.players.first.id);
    game.confirmSuspect(now);
    game.advanceTime(now.add(GameRound.revealDuration));
    game.newRound();
    expect(game.round!.discussionDuration, const Duration(seconds: 75));
    expect(game.round!.discussionEndsAt, isNull);
    distribute(game);
    game.setDiscussionDuration(null);
    expect(game.round!.discussionDuration, const Duration(seconds: 45));
    game.startDiscussion(now);
    game.advanceTime(now.add(const Duration(hours: 2)));
    expect(game.round!.phase, GamePhase.voting);
    game.returnToGroup();
    game.addPlayer('Dana');
    expect(game.discussionDuration, const Duration(minutes: 1));
  });
}
