import 'dart:ui' show SemanticsAction, SemanticsActionEvent;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';
import 'package:secret_word_society/game/word_catalog.dart';

import 'support/curtain_geometry.dart';

import 'widget_test.dart'
    show
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
    'next is always active and skips unseen cards safely through ready',
    (tester) async {
      await startTestRound(tester);
      for (final name in ['Anna', 'Ben', 'Cem']) {
        expect(find.text(name), findsOneWidget);
        expect(find.text('Gruppe bearbeiten'), findsNothing);
        expectConcealed(tester);
        final panel = tester.getRect(
          find.byKey(const ValueKey('secret-curtain-panel')),
        );
        expect(
          panel.bottom,
          tester.getRect(find.byType(CustomScrollView)).bottom,
        );
        final next = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .onPressed;
        expect(next, isNotNull);
        await tapVisible(tester, 'Weiter');
        next!(); // A callback from the previous person cannot skip another one.
        await tester.pumpAndSettle();
        expectConcealed(tester);
      }
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      expect(find.text('Gruppe bearbeiten'), findsNothing);
    },
  );

  testWidgets(
    'dragging avatar, name, background and button reveals without advancing',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      await startTestRound(tester);
      var imposters = 0;
      for (final name in ['Anna', 'Ben', 'Cem']) {
        for (final area in ['avatar', 'name', 'background', 'button']) {
          final panel = tester.getRect(
            find.byKey(const ValueKey('secret-curtain-panel')),
          );
          final startGrip = tester.getCenter(_curtain);
          final start = switch (area) {
            'avatar' => tester.getCenter(
              find.byKey(const ValueKey('curtain-avatar')),
            ),
            'name' => tester.getCenter(find.text(name)),
            'button' => tester.getCenter(find.text('Weiter')),
            _ => panel.topLeft + const Offset(12, 24),
          };
          final gesture = await tester.startGesture(start);
          await gesture.moveBy(const Offset(0, -60));
          await tester.pump();
          expect(tester.getCenter(_curtain).dy, closeTo(startGrip.dy - 60, .1));
          expectPreview(tester);
          await gesture.moveBy(const Offset(0, -220));
          await tester.pump();
          final secret = find.text('Popcorn').evaluate().isNotEmpty
              ? 'Popcorn'
              : 'Kino';
          expect(semanticsTree(tester), contains(secret));
          final distance = startGrip.dy - tester.getCenter(_curtain).dy;
          expect(distance, lessThan(panel.height * .6));
          expect(
            tester.getRect(find.text(secret)).top,
            greaterThan(tester.getRect(_curtain).bottom),
          );
          await gesture.up();
          await tester.pumpAndSettle();
          expectConcealed(tester);
          expect(find.text(name), findsOneWidget);
        }
        final full = await _hold(tester);
        if (find.text('Du bist der Imposter').evaluate().isNotEmpty) {
          imposters++;
        }
        await full.up();
        await tester.pumpAndSettle();
        await tapVisible(tester, 'Weiter');
      }
      expect(imposters, 1);
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      semantics.dispose();
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
      await tester.pumpWidget(MyApp(catalogLoader: () async => catalog));
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
        expect(
          tester.getCenter(_curtain).dy,
          closeTo(
            tester
                    .getRect(find.byKey(const ValueKey('secret-curtain-panel')))
                    .bottom -
                54,
            .1,
          ),
        );
        await tapVisible(tester, 'Weiter');
        expect(tester.takeException(), isNull);
      }
      expect(imposters, 1);
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
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
      final titleStart = tester.getCenter(find.text('Anna'));
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
        tester.getCenter(find.text('Anna')).dy,
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
      expectConcealed(tester);
      await tester.pumpAndSettle();
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy, 0.1));
      semantics.dispose();
    },
  );

  testWidgets(
    'text is progressively uncovered before the stop for word and hint',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await startTestRound(tester);
      var hints = 0;
      for (var person = 0; person < 3; person++) {
        await tester.ensureVisible(_curtain);
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(tester.getCenter(_curtain));
        await gesture.moveBy(const Offset(0, -60));
        await tester.pump();
        expectPreview(tester);
        if (find.text('Du bist der Imposter').evaluate().isNotEmpty) hints++;
        final before = openingBounds(tester);
        expect(before.top, greaterThan(0));
        expect(before.height, greaterThan(0));
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        final secret = find.text('Popcorn').evaluate().isNotEmpty
            ? 'Popcorn'
            : 'Kino';
        final textRect = tester.getRect(find.text(secret));
        await gesture.moveBy(const Offset(0, -40));
        await tester.pump();
        expectPreview(tester);
        expect(openingBounds(tester).top, closeTo(before.top - 40, 0.1));
        expect(tester.getRect(find.text(secret)), textRect);
        await gesture.up();
        await tester.pumpAndSettle();
        expectConcealed(tester);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        final full = await _hold(tester);
        expect(semanticsTree(tester), contains(secret));
        await full.up();
        await tester.pumpAndSettle();
        expectConcealed(tester);
        final again = await tester.startGesture(tester.getCenter(_curtain));
        await again.moveBy(const Offset(0, -60));
        await tester.pump();
        expectPreview(tester);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        await again.up();
        await tester.pumpAndSettle();
        expectConcealed(tester);
        await tapVisible(tester, 'Weiter');
      }
      expect(hints, 1);
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('hold, release, repeat, cancel and separate concealed handoff', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await startTestRound(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.ensureVisible(_curtain);
    await tester.tap(_curtain);
    await tester.pump();
    expectConcealed(tester);
    for (var i = 0; i < 3; i++) {
      final gesture = await _hold(tester);
      final secret = find.text('Popcorn').evaluate().isNotEmpty
          ? 'Popcorn'
          : 'Kino';
      expect(find.text(secret), findsOneWidget);
      expect(semanticsTree(tester), contains(secret));
      expect(find.text('Person 1 von 3'), findsOneWidget);
      if (i == 1) {
        await gesture.cancel();
      } else {
        await gesture.up();
      }
      await tester.pump();
      expectConcealed(tester);
      await tester.pumpAndSettle();
    }
    await tapVisible(tester, 'Weiter');
    expect(find.text('Ben'), findsOneWidget);
    expectConcealed(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    semantics.dispose();
  });

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
    'same-frame release and advancing while held cannot leak secrets',
    (tester) async {
      await startTestRound(tester);
      await tester.ensureVisible(_curtain);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(_curtain));
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      final advance = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      advance();
      advance();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsOneWidget);
      expectConcealed(tester);
      await tester.ensureVisible(_curtain);
      await tester.pumpAndSettle();
      final quick = await tester.startGesture(tester.getCenter(_curtain));
      await quick.moveBy(const Offset(0, -30));
      await quick.moveBy(const Offset(0, -260));
      await quick.up();
      await tester.pump();
      expectConcealed(tester);
    },
  );

  testWidgets(
    'semantics and keyboard peek expire and interruptions cancel expiry',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await startTestRound(tester);
      await tester.ensureVisible(_curtain);
      await tester.pumpAndSettle();
      final node = tester.getSemantics(
        find.bySemanticsLabel('Geheimnis kurz ansehen'),
      );
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: node.id,
        ),
      );
      await tester.pump();
      expect(
        find.text('Popcorn').evaluate().isNotEmpty ||
            find.text('Kino').evaluate().isNotEmpty,
        isTrue,
      );
      await tester.pump(const Duration(seconds: 8));
      expectConcealed(tester);
      await tester.pumpAndSettle();
      Focus.of(tester.element(_curtain)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        find.text('Popcorn').evaluate().isNotEmpty ||
            find.text('Kino').evaluate().isNotEmpty,
        isTrue,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expectConcealed(tester);
      await tester.pump(const Duration(seconds: 9));
      expectConcealed(tester);
      semantics.dispose();
    },
  );
}
