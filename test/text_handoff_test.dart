import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/word_catalog.dart';
import 'package:secret_word_society/main.dart';

import 'support/handoff.dart';
import 'widget_test.dart'
    show
        startTestRound,
        expectConcealed,
        semanticsTree,
        pumpPreparation,
        addName,
        showStart,
        tapVisible,
        leaveRound;

Finder get _surface => find
    .byWidgetPredicate(
      (widget) =>
          widget is GestureDetector && widget.onVerticalDragUpdate != null,
    )
    .last;

Future<TestGesture> _dragToVisibleFraction(
  WidgetTester tester,
  double fraction, {
  List<String> secrets = const ['Popcorn', 'Kino'],
}) async {
  await tester.ensureVisible(_surface);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(_surface));
  await gesture.moveBy(const Offset(0, -24));
  await tester.pump();
  await _moveToVisibleFraction(tester, gesture, fraction, secrets);
  return gesture;
}

Future<void> _moveToVisibleFraction(
  WidgetTester tester,
  TestGesture gesture,
  double fraction,
  List<String> secrets,
) async {
  final secret = find.text(
    secrets.singleWhere((text) => find.text(text).evaluate().isNotEmpty),
  );
  final text = tester.getRect(secret);
  final target = Offset(text.center.dx, text.bottom - text.height * fraction);
  final shape = find
      .descendant(
        of: find.byKey(const ValueKey('secret-curtain-cover')),
        matching: find.byType(PhysicalShape),
      )
      .first;
  for (var step = 0; step < 300; step++) {
    final mask = tester
        .widget<PhysicalShape>(shape)
        .clipper
        .getClip(tester.getSize(shape))
        .shift(tester.getTopLeft(shape));
    if (!mask.contains(target)) return;
    await gesture.moveBy(const Offset(0, -1));
    await tester.pump();
  }
  fail('The requested part of the secret never became visible');
}

void main() {
  for (final large in [false, true]) {
    for (final accessible in [false, true]) {
      testWidgets(
        'text threshold survives dragging back, large=$large, accessible=$accessible',
        (tester) async {
          tester.view.physicalSize = large
              ? const Size(320, 568)
              : const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(
                accessibleNavigation: accessible,
                disableAnimations: large && !accessible,
              );
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
          const secrets = [
            'Eine große Geburtstagsüberraschung',
            'Gemeinsames besonderes Erlebnis',
          ];
          final catalog = WordCatalog(
            languageCode: 'de',
            pairs: [
              WordPair(id: 'wrapped', word: secrets[0], hint: secrets[1]),
            ],
          );
          await pumpPreparation(
            tester,
            MyApp(catalogLoader: () async => catalog),
          );
          for (final name in ['Anna', 'Ben', 'Cem']) {
            await addName(tester, name);
          }
          await showStart(tester);
          await tapVisible(tester, 'Runde starten');
          Finder getButton() =>
              find.widgetWithText(FilledButton, 'Verdecken und weitergeben');
          for (var person = 0; person < 3; person++) {
            final gesture = await _dragToVisibleFraction(
              tester,
              .25,
              secrets: secrets,
            );
            final name = handoffName(tester);
            if (accessible) {
              expect(
                tester.widget<FilledButton>(getButton()).onPressed,
                isNull,
              );
            }
            await _moveToVisibleFraction(tester, gesture, .55, secrets);
            if (accessible) {
              expect(
                tester.widget<FilledButton>(getButton()).onPressed,
                isNotNull,
              );
            }
            await gesture.moveBy(const Offset(0, 200));
            await tester.pump();
            if (accessible) {
              expect(
                tester.widget<FilledButton>(getButton()).onPressed,
                isNotNull,
              );
            }
            expect(handoffName(tester), name);
            await gesture.up();
            await tester.pumpAndSettle();
            expectConcealed(tester);
            if (person < 2) expect(handoffName(tester), isNot(name));
          }
          expect(find.text('Alle eingeweiht?'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final interruption in ['cancel', 'lifecycle', 'dialog']) {
    testWidgets('half-text permission resets on $interruption', (tester) async {
      await startTestRound(tester);
      final name = handoffName(tester);
      final enough = await _dragToVisibleFraction(tester, .55);
      if (interruption == 'cancel') {
        await enough.cancel();
      } else if (interruption == 'lifecycle') {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await enough.up();
      } else {
        await leaveRound(tester);
        await enough.up();
        await tapVisible(tester, 'Weiterspielen');
      }
      await tester.pumpAndSettle();
      expectConcealed(tester);
      expect(handoffName(tester), name);
      final partial = await _dragToVisibleFraction(tester, .25);
      await partial.up();
      await tester.pumpAndSettle();
      expect(handoffName(tester), name);
      expectConcealed(tester);
    });
  }
  testWidgets(
    'half-visible word and hint allow release through the last card',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await startTestRound(tester);
      var hints = 0;
      for (var person = 0; person < 3; person++) {
        final name = handoffName(tester);
        final partial = await _dragToVisibleFraction(tester, .25);
        await partial.up();
        await tester.pumpAndSettle();
        expect(handoffName(tester), name);
        expectConcealed(tester);

        final enough = await _dragToVisibleFraction(tester, .55);
        if (find.text('Kino').evaluate().isNotEmpty) hints++;
        expect(semanticsTree(tester), isNot(contains('Popcorn')));
        expect(semanticsTree(tester), isNot(contains('Kino')));
        await enough.up();
        await tester.pump();
        expect(
          handoffName(tester),
          name,
          reason: 'Close before changing person',
        );
        await tester.pumpAndSettle();
        expectConcealed(tester);
        if (person < 2) expect(handoffName(tester), isNot(name));
      }
      expect(hints, 1);
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      semantics.dispose();
    },
  );
}
