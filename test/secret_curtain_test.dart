import 'dart:ui' show SemanticsAction, SemanticsActionEvent;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart'
    show startTestRound, tapVisible, expectConcealed, semanticsTree;

Finder get _curtain => find.byKey(const ValueKey('secret-curtain-gesture'));

Future<TestGesture> _hold(WidgetTester tester) async {
  await tester.ensureVisible(_curtain);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(_curtain));
  await gesture.moveBy(const Offset(0, -30));
  await tester.pump();
  await gesture.moveBy(const Offset(0, -120));
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('hold, release, repeat, cancel and separate concealed handoff', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await startTestRound(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
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
    expect(find.text('Handy an Ben.'), findsOneWidget);
    expectConcealed(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
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
      final gesture = await _hold(tester);
      final advance = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      advance();
      advance();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Handy an Ben.'), findsOneWidget);
      expectConcealed(tester);
      await tester.ensureVisible(_curtain);
      await tester.pumpAndSettle();
      final quick = await tester.startGesture(tester.getCenter(_curtain));
      await quick.moveBy(const Offset(0, -30));
      await quick.moveBy(const Offset(0, -120));
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
