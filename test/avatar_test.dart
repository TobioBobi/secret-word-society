import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/game/player_avatar.dart';
import 'package:secret_word_society/main.dart';
import 'package:secret_word_society/ui/player_avatar.dart';

import 'widget_test.dart' show addName, showStart, tapVisible, testCatalog;

void main() {
  test('avatar survives rename, group navigation and follow-up rounds', () {
    final session = GameSession()
      ..addPlayer('Anna')
      ..addPlayer('Ben')
      ..addPlayer('Cem');
    final original = session.players.first;
    session.rerollAvatar(original.id);
    final avatar = session.players.first.avatar;
    expect(avatar.seed, isNot(original.avatar.seed));
    expect(session.renamePlayer(original.id, 'Anni'), isNull);
    expect(session.players.first.id, original.id);
    expect(session.players.first.avatar, same(avatar));
    expect(session.renamePlayer(original.id, 'ben'), NameProblem.duplicate);
    expect(session.renamePlayer(original.id, ' '), NameProblem.empty);
    session.startRound(testCatalog, random: Random(1));
    expect(session.round!.currentPlayer!.avatar, same(avatar));
    expect(() => session.rerollAvatar(original.id), throwsStateError);
    expect(() => session.renamePlayer(original.id, 'Other'), throwsStateError);
    while (session.round!.canAdvanceCard) {
      session.hideAndAdvance();
    }
    final now = DateTime.utc(2026);
    session.startDiscussion(now);
    session.advanceTime(now.add(const Duration(minutes: 2)));
    session.selectSuspect(original.id);
    session.confirmSuspect(now);
    session.advanceTime(now.add(const Duration(seconds: 3)));
    expect(session.round!.result!.suspect.avatar, same(avatar));
    session.newRound();
    expect(session.round!.currentPlayer!.avatar, same(avatar));
    session.returnToGroup();
    expect(session.players.first.avatar, same(avatar));
    session.removePlayer(original.id);
    session.addPlayer('Anni');
    expect(session.players.last.id, isNot(original.id));
    expect(session.players.last.avatar.seed, isNot(avatar.seed));
  });
  test('Cutouts SVG can be reconstructed with only its seed', () {
    final one = PlayerAvatarView.svgFor(const PlayerAvatar(seed: 'party'));
    expect(one, contains('<svg'));
    expect(one, PlayerAvatarView.svgFor(const PlayerAvatar(seed: 'party')));
    expect(
      one,
      isNot(PlayerAvatarView.svgFor(const PlayerAvatar(seed: 'other'))),
    );
    expect(one, isNot(contains('https://api.dicebear')));
  });
  for (final large in [false, true]) {
    testWidgets(
      'reroll and rename directly, accessible controls, large=$large',
      (tester) async {
        tester.view.physicalSize = large
            ? const Size(320, 568)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MyApp(catalogLoader: () async => testCatalog),
          );
          await addName(tester, 'Anna');
          final reroll = find.byKey(const ValueKey('reroll-player-0'));
          await tester.ensureVisible(reroll);
          await tester.pumpAndSettle();
          final original = tester
              .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
              .avatar;
          await tester.tap(reroll);
          await tester.pumpAndSettle();
          final changed = tester
              .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
              .avatar;
          expect(changed.seed, isNot(original.seed));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await tapVisible(tester, 'Anna');
          await tester.enterText(find.byType(TextField).last, 'Anni');
          await tester.tap(find.text('\u00dcbernehmen'));
          await tester.pumpAndSettle();
          expect(find.text('Anni'), findsOneWidget);
          expect(
            tester
                .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
                .avatar,
            same(changed),
          );
          await addName(tester, 'Ben');
          await addName(tester, 'Cem');
          await showStart(tester);
          await tapVisible(tester, 'Runde starten');
          expect(
            tester
                .widget<PlayerAvatarView>(find.byType(PlayerAvatarView))
                .avatar,
            same(changed),
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
