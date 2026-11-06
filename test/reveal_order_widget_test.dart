import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';
import 'package:secret_word_society/ui/player_avatar.dart';

import 'support/handoff.dart';
import 'widget_test.dart'
    show
        pumpPreparation,
        addName,
        showStart,
        tapVisible,
        leaveRound,
        expectConcealed,
        semanticsTree,
        testCatalog;

void main() {
  for (final large in [false, true]) {
    testWidgets(
      'shuffled handoff retains names, images and progress, large=$large',
      (tester) async {
        tester.view.physicalSize = large
            ? const Size(320, 568)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        final semantics = tester.ensureSemantics();
        try {
          const names = [
            'Alexandra Maximiliane',
            'Benjamin Konstantin',
            'Charlotte Friederike',
          ];
          await pumpPreparation(
            tester,
            MyApp(catalogLoader: () async => testCatalog),
          );
          for (final name in names) {
            await addName(tester, name);
          }
          final avatars = await groupAvatars(tester, names);
          await showStart(tester);
          await tapVisible(tester, 'Runde starten');
          final first = handoffName(tester, names);
          final seen = <String>{};
          for (var index = 0; index < names.length; index++) {
            final name = handoffName(tester, names);
            expect(seen.add(name), isTrue);
            expect(find.text('Person ${index + 1} von 3'), findsOneWidget);
            expect(semanticsTree(tester), contains(name));
            expect(
              tester
                  .widget<PlayerAvatarView>(find.byType(PlayerAvatarView))
                  .avatar,
              same(avatars[name]),
            );
            expectConcealed(tester);
            await tapVisible(tester, 'Geheimnis kurz ansehen');
            final secret = find.text('Kino').evaluate().isEmpty
                ? 'Popcorn'
                : 'Kino';
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pumpAndSettle();
            expect(handoffName(tester, names), name);
            expectConcealed(tester);
            await tapVisible(tester, 'Geheimnis kurz ansehen');
            expect(find.text(secret), findsOneWidget);
            await tapVisible(tester, 'Verdecken und weitergeben');
            expect(tester.takeException(), isNull);
          }
          expect(seen, names.toSet());
          await leaveRound(tester);
          await tapVisible(tester, 'Runde verlassen');
          await showStart(tester);
          await tapVisible(tester, 'Runde starten');
          expect(handoffName(tester, names), isNot(first));
          expectConcealed(tester);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
