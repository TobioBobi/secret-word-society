import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/game/player_photo.dart';
import 'package:secret_word_society/l10n/app_localizations.dart';
import 'package:secret_word_society/ui/party_theme.dart';
import 'package:secret_word_society/ui/session_screen.dart';

import 'safe_handoff_test.dart' show openCurtain;
import 'support/handoff.dart';
import 'widget_test.dart'
    show startTestRound, expectConcealed, testCatalog, semanticsTree;

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'photo handoffs stay accessible at large text, reduced=$reduced',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(
              accessibleNavigation: true,
              disableAnimations: reduced,
            );
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final semantics = tester.ensureSemantics();
        final session = GameSession();
        for (final name in [
          'Alexandra Maximiliane',
          'Benjamin Konstantin',
          'Charlotte Friederike',
        ]) {
          session.addPlayer(name);
        }
        final bytes = img.encodePng(img.Image(width: 24, height: 32));
        final photo = PlayerPhoto(
          PhotoSource(bytes, [0, 0, 24, 32], [12, 16], [
            [8, 10],
            [16, 10],
          ]),
          bytes,
          PhotoEffect.nose,
        );
        for (final player in session.players) {
          session.setPhoto(player.id, photo);
        }
        session.startRound(testCatalog, random: Random(75));
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildPartyTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SessionScreen(session: session, nameController: controller),
          ),
        );
        await tester.pumpAndSettle();
        final names = session.players.map((p) => p.name).toList();
        final visited = <String>{};
        for (var i = 0; i < 3; i++) {
          final name = handoffName(tester, names);
          expect(visited.add(name), isTrue);
          expect(
            find.text(i == 0 ? 'Handy an' : 'Gib weiter an'),
            findsOneWidget,
          );
          expect(find.text(name), findsOneWidget);
          expect(
            semanticsTree(tester),
            contains('${i == 0 ? 'Handy an' : 'Gib weiter an'} $name.'),
          );
          expectConcealed(tester);
          final avatar = find.byKey(const ValueKey('curtain-avatar'));
          if (i > 0) {
            final entry = tester.getRect(avatar);
            final heading = tester.getRect(find.text(name));
            await tester.pump(const Duration(milliseconds: 250));
            expect(tester.getRect(avatar), reduced ? entry : isNot(entry));
            expect(tester.getRect(find.text(name)), heading);
          }
          // Screenreader reveal works during an entrance, without waiting.
          final action = find.byKey(const ValueKey('secret-peek-action'));
          tester.widget<Semantics>(action).properties.onTap!();
          await tester.pump();
          expect(
            find.text('Popcorn').evaluate().isNotEmpty ||
                find.text('Kino').evaluate().isNotEmpty,
            isTrue,
          );
          await tester.ensureVisible(find.text('Verdecken und weitergeben'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Verdecken und weitergeben'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.text('Alle eingeweiht?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'first person rests; next avatar enters after complete concealment',
    (tester) async {
      await startTestRound(tester);
      final avatar = find.byKey(const ValueKey('curtain-avatar'));
      final first = handoffName(tester);
      expect(find.text('Handy an'), findsOneWidget);
      final resting = tester.getRect(avatar);
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getRect(avatar), resting);

      final gesture = await openCurtain(tester);
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      expect(handoffName(tester), first);
      expect(find.text('Gib weiter an'), findsNothing);
      await tester.pump(const Duration(milliseconds: 160));
      await tester.pump();
      final next = handoffName(tester);
      expect(next, isNot(first));
      expectConcealed(tester);
      expect(find.text('Gib weiter an'), findsOneWidget);
      final heading = tester.getRect(find.text(next));
      final incoming = tester.getRect(avatar);
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getRect(avatar), isNot(incoming));
      expect(tester.getRect(find.text(next)), heading);

      // The next person can already reveal, before the 500 ms entrance ends.
      final nextGesture = await openCurtain(tester);
      expect(
        find.text('Popcorn').evaluate().isNotEmpty ||
            find.text('Kino').evaluate().isNotEmpty,
        isTrue,
      );
      await nextGesture.up();
      await tester.pumpAndSettle();
      expectConcealed(tester);
    },
  );
}
