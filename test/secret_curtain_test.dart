import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/word_catalog.dart';
import 'package:secret_word_society/main.dart';

import 'support/handoff.dart';
import 'widget_test.dart'
    show
        pumpPreparation,
        startTestRound,
        tapVisible,
        expectConcealed,
        semanticsTree,
        addName,
        showStart,
        leaveRound;

Finder get _curtain => find.byKey(const ValueKey('secret-curtain-gesture'));
Finder get _opening => find.byKey(const ValueKey('secret-curtain-opening'));

void expectPreview(WidgetTester tester) {
  expect(_opening, findsOneWidget);
  expect(
    find.text('Popcorn').evaluate().isNotEmpty ||
        find.text('Kino').evaluate().isNotEmpty,
    isTrue,
  );
  for (final secret in ['Popcorn', 'Kino', 'Du bist der Imposter']) {
    expect(semanticsTree(tester), isNot(contains(secret)));
  }
}

Future<TestGesture> _hold(WidgetTester tester) async {
  await tester.ensureVisible(_curtain);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(_curtain));
  final panel = tester.getRect(
    find.byKey(const ValueKey('secret-curtain-panel')),
  );
  await gesture.moveBy(const Offset(0, -30));
  await tester.pump();
  await gesture.moveTo(Offset(panel.center.dx, panel.top + 32));
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets(
    'a small accidental drag leaves word and hint fully behind the curve',
    (tester) async {
      await startTestRound(tester);
      var hints = 0;
      for (var person = 0; person < 3; person++) {
        await tester.ensureVisible(_curtain);
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(tester.getCenter(_curtain));
        await gesture.moveBy(const Offset(0, -24));
        await tester.pump();
        expectPreview(tester);
        final isHint = find.text('Kino').evaluate().isNotEmpty;
        if (isHint) hints++;
        final text = tester.getRect(find.text(isHint ? 'Kino' : 'Popcorn'));
        final cover = find
            .descendant(
              of: find.byKey(const ValueKey('secret-curtain-cover')),
              matching: find.byType(PhysicalShape),
            )
            .first;
        final mask = tester
            .widget<PhysicalShape>(cover)
            .clipper
            .getClip(tester.getSize(cover))
            .shift(tester.getTopLeft(cover));
        for (final point in [
          text.topLeft,
          text.topRight,
          text.bottomLeft,
          text.bottomRight,
        ]) {
          expect(
            mask.contains(point),
            isTrue,
            reason: 'Secret must stay behind the real cover after a small drag',
          );
        }
        await gesture.up();
        await tester.pumpAndSettle();
        expectConcealed(tester);
        final full = await _hold(tester);
        await full.up();
        await tester.pumpAndSettle();
      }
      expect(hints, 1);
    },
  );

  testWidgets(
    'back while held then cancelling the dialog permits a fresh drag',
    (tester) async {
      await startTestRound(tester);
      final old = await _hold(tester);
      await leaveRound(tester);
      expectConcealed(tester);
      await old.up();
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Weiterspielen');
      expectConcealed(tester);
      final fresh = await _hold(tester);
      expect(
        find.text('Popcorn').evaluate().isNotEmpty ||
            find.text('Kino').evaluate().isNotEmpty,
        isTrue,
      );
      await fresh.up();
      await tester.pumpAndSettle();
      expectConcealed(tester);
    },
  );

  testWidgets(
    'small screen with system bars, long secrets and reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final catalog = WordCatalog(
        languageCode: 'de',
        pairs: [
          WordPair(
            id: 'long',
            word: 'Geburtstagsüberraschung',
            hint: 'Gemeinsames Erlebnis',
          ),
        ],
      );
      await pumpPreparation(tester, MyApp(catalogLoader: () async => catalog));
      for (final name in [
        'Alexandra Maximiliane',
        'Benjamin Konstantin',
        'Charlotte Friederike',
      ]) {
        await addName(tester, name);
      }
      await showStart(tester);
      await tapVisible(tester, 'Runde starten');
      var imposters = 0;
      for (var person = 0; person < 3; person++) {
        final full = await _hold(tester);
        final grip = tester.getRect(_curtain);
        expect(grip.top, greaterThanOrEqualTo(24));
        expect(grip.bottom, lessThanOrEqualTo(544));
        final isImposter = find
            .text('Du bist der Imposter')
            .evaluate()
            .isNotEmpty;
        if (isImposter) imposters++;
        final secret = tester.getRect(
          find.text(
            isImposter ? 'Gemeinsames Erlebnis' : 'Geburtstagsüberraschung',
          ),
        );
        expect(secret.left, greaterThanOrEqualTo(0));
        expect(secret.right, lessThanOrEqualTo(320));
        expect(secret.top, greaterThanOrEqualTo(grip.bottom));
        expect(
          secret.bottom,
          lessThan(
            tester
                .getRect(find.byKey(const ValueKey('secret-curtain-panel')))
                .bottom,
          ),
        );
        await full.up();
        await tester.pump();
        expect(find.text('Geburtstagsüberraschung'), findsNothing);
        expect(find.text('Gemeinsames Erlebnis'), findsNothing);
        if (person < 2) {
          expect(
            tester.getCenter(_curtain).dy,
            closeTo(
              tester
                      .getRect(
                        find.byKey(const ValueKey('secret-curtain-panel')),
                      )
                      .bottom -
                  54,
              .1,
            ),
          );
        }
        expect(tester.takeException(), isNull);
      }
      expect(imposters, 1);
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
    },
  );

  testWidgets(
    'interrupted held and partial drags stay closed until a new gesture',
    (tester) async {
      await startTestRound(tester);
      for (final full in [false, true]) {
        TestGesture gesture;
        if (full) {
          gesture = await _hold(tester);
        } else {
          await tester.ensureVisible(_curtain);
          await tester.pumpAndSettle();
          gesture = await tester.startGesture(tester.getCenter(_curtain));
          await gesture.moveBy(const Offset(0, -30));
          await tester.pump();
        }
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        // An old pointer can deliver another move before the resume frame.
        await gesture.moveBy(const Offset(0, -150));
        await tester.pump();
        expectConcealed(tester);
        await gesture.moveBy(const Offset(0, -150));
        await tester.pump();
        expectConcealed(tester);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('Person 1 von 3'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'cover follows the finger without acceleration and keeps its grip',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await startTestRound(tester);
      await tester.ensureVisible(_curtain);
      await tester.pumpAndSettle();
      final start = tester.getCenter(_curtain);
      final panel = tester.getRect(
        find.byKey(const ValueKey('secret-curtain-panel')),
      );
      final avatarStart = tester.getCenter(
        find.byKey(const ValueKey('curtain-avatar')),
      );
      final titleStart = tester.getCenter(find.text(handoffName(tester)));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy - 60, 0.1));
      expectPreview(tester);
      expect(
        tester.getCenter(find.byKey(const ValueKey('curtain-avatar'))).dy,
        closeTo(avatarStart.dy - 60, .1),
      );
      expect(
        tester.getCenter(find.text(handoffName(tester))).dy,
        closeTo(titleStart.dy - 60, .1),
      );
      final avatar = tester.getCenter(
        find.byKey(const ValueKey('curtain-avatar')),
      );
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      expect(
        tester.getCenter(find.byKey(const ValueKey('curtain-avatar'))).dy,
        closeTo(avatar.dy - 20, 0.1),
      );
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy - 60, 0.1));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy - 40, 0.1));
      await gesture.moveTo(Offset(start.dx, panel.top + 32));
      await tester.pump();
      final stoppedAt = tester.getCenter(_curtain).dy;
      expect(stoppedAt, greaterThan(panel.top + 64));
      expect(
        find.text('Popcorn').evaluate().isNotEmpty ||
            find.text('Kino').evaluate().isNotEmpty,
        isTrue,
      );
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      expect(tester.getCenter(_curtain).dy, closeTo(stoppedAt, 0.1));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(tester.getCenter(_curtain).dy, closeTo(stoppedAt + 30, 0.1));
      expectPreview(tester);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy, 0.1));
      final flick = await tester.startGesture(start);
      await flick.moveBy(const Offset(0, -60));
      await tester.pump();
      final releasedAt = tester.getCenter(_curtain).dy;
      await flick.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getCenter(_curtain).dy, greaterThanOrEqualTo(releasedAt));
      expectPreview(tester);
      await tester.pumpAndSettle();
      expectConcealed(tester);
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy, 0.1));
      semantics.dispose();
    },
  );
}
