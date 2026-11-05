import 'dart:ui' show SemanticsAction, SemanticsActionEvent;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/handoff.dart';
import 'widget_test.dart'
    show startTestRound, expectConcealed, semanticsTree, tapVisible, leaveRound;

Finder get grip => find.byKey(const ValueKey('secret-curtain-gesture'));

Future<TestGesture> openCurtain(WidgetTester tester) async {
  final gesture = await tester.startGesture(tester.getCenter(grip));
  await gesture.moveBy(const Offset(0, -30));
  await tester.pump();
  await gesture.moveBy(const Offset(0, -300));
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('partial viewing and re-grabbing require a completed return', (
    tester,
  ) async {
    await startTestRound(tester);
    final name = handoffName(tester);
    final partial = await tester.startGesture(tester.getCenter(grip));
    await partial.moveBy(const Offset(0, -60));
    await tester.pump();
    await partial.up();
    await tester.pumpAndSettle();
    expect(handoffName(tester), name);
    expectConcealed(tester);
    final full = await openCurtain(tester);
    final secret = find.text('Popcorn').evaluate().isEmpty ? 'Kino' : 'Popcorn';
    final position = tester.getRect(find.text(secret));
    await full.up();
    await tester.pump();
    expect(tester.getRect(find.text(secret)), position);
    await tester.pump(const Duration(milliseconds: 40));
    final again = await tester.startGesture(tester.getCenter(grip));
    await tester.pump(const Duration(seconds: 1));
    expect(handoffName(tester), name);
    expect(tester.getRect(find.text(secret)), position);
    await again.moveBy(const Offset(0, 25));
    await tester.pump();
    await again.up();
    await tester.pumpAndSettle();
    expect(handoffName(tester), isNot(name));
    expectConcealed(tester);
  });

  for (final duringReturn in [false, true]) {
    testWidgets(
      'cancellation or interruption invalidates handoff, returning=$duringReturn',
      (tester) async {
        await startTestRound(tester);
        final name = handoffName(tester);
        final full = await openCurtain(tester);
        if (duringReturn) {
          await full.up();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 40));
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        } else {
          await full.cancel();
        }
        await tester.pumpAndSettle();
        expect(handoffName(tester), name);
        expectConcealed(tester);
        final partial = await tester.startGesture(tester.getCenter(grip));
        await partial.moveBy(const Offset(0, -30));
        await partial.up();
        await tester.pumpAndSettle();
        expect(handoffName(tester), name);
        final fresh = await openCurtain(tester);
        await fresh.up();
        await tester.pumpAndSettle();
        expect(handoffName(tester), isNot(name));
      },
    );
  }

  testWidgets('an already resting second finger cannot open the next secret', (
    tester,
  ) async {
    await startTestRound(tester);
    final full = await openCurtain(tester);
    final second = await tester.startGesture(
      tester.getCenter(grip),
      pointer: 7,
    );
    await full.up();
    await tester.pumpAndSettle();
    final name = handoffName(tester);
    await second.moveBy(const Offset(0, -300));
    await tester.pumpAndSettle();
    expectConcealed(tester);
    expect(handoffName(tester), name);
    await second.up();
    final fresh = await openCurtain(tester);
    await fresh.up();
    await tester.pumpAndSettle();
    expectConcealed(tester);
  });

  testWidgets(
    'accessible expiry only conceals; keyboard hands off consciously',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await startTestRound(tester);
      final name = handoffName(tester);
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
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
      expectConcealed(tester);
      expect(handoffName(tester), name);
      final button = find.text('Verdecken und weitergeben');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tapVisible(tester, 'Geheimnis kurz ansehen');
      await leaveRound(tester);
      await tapVisible(tester, 'Weiterspielen');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      Focus.of(tester.element(find.byKey(const ValueKey('secret-peek-action'))))
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      Focus.of(tester.element(button)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(handoffName(tester), isNot(name));
      expectConcealed(tester);
      expect(find.bySemanticsLabel('Geheimnis kurz ansehen'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets(
    'complete viewing hands off only after release and full closure',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await startTestRound(tester);
      expect(find.text('Weiter'), findsNothing);
      final seen = <String>{};
      var hints = 0;
      for (var i = 0; i < 3; i++) {
        final name = handoffName(tester);
        expect(seen.add(name), isTrue);
        final gesture = await openCurtain(tester);
        if (find.text('Kino').evaluate().isNotEmpty) hints++;
        await gesture.moveBy(const Offset(0, 500));
        await tester.pump();
        expect(handoffName(tester), name);
        await gesture.up();
        await tester.pumpAndSettle();
        expectConcealed(tester);
        expect(semanticsTree(tester), isNot(contains('Popcorn')));
        if (i < 2) expect(handoffName(tester), isNot(name));
      }
      expect(hints, 1);
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      semantics.dispose();
    },
  );
}
