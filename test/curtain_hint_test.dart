import 'dart:math';
import 'dart:ui' show SemanticsAction, SemanticsActionEvent;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/l10n/app_localizations.dart';
import 'package:secret_word_society/ui/party_theme.dart';
import 'package:secret_word_society/ui/session_screen.dart';

import 'widget_test.dart' show testCatalog, expectConcealed;
import 'safe_handoff_test.dart' show openCurtain;

Finder get grip => find.byKey(const ValueKey('secret-curtain-gesture'));

Future<GameSession> startCard(WidgetTester tester) async {
  final session = GameSession();
  for (final name in ['Anna', 'Ben', 'Cem']) {
    session.addPlayer(name);
  }
  session.startRound(testCatalog, random: Random(80));
  final names = TextEditingController();
  addTearDown(names.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildPartyTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SessionScreen(session: session, nameController: names),
    ),
  );
  await tester.pump();
  return session;
}

void main() {
  testWidgets('enabling reduced motion immediately stops an active tug', (
    tester,
  ) async {
    await startCard(tester);
    final rest = tester.getCenter(grip).dy;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.getCenter(grip).dy, lessThan(rest - 2));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(tester.getCenter(grip).dy, closeTo(rest, .01));
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getCenter(grip).dy, closeTo(rest, .01));
      expectConcealed(tester);
    }
    await tester.pumpWidget(const SizedBox());
  });

  for (final interruption in ['dialog', 'background']) {
    testWidgets('hint pauses during $interruption and returns safely', (
      tester,
    ) async {
      final session = await startCard(tester);
      final person = session.round!.currentPlayer;
      final rest = tester.getCenter(grip).dy;
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getCenter(grip).dy, lessThan(rest - 2));
      if (interruption == 'dialog') {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      } else {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
      }
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.getCenter(grip).dy, closeTo(rest, .01));
        expectConcealed(tester);
        expect(session.round!.currentPlayer, person);
        expect(session.round!.canAdvanceCard, isFalse);
      }
      if (interruption == 'dialog') {
        await tester.tap(find.text('Weiterspielen'));
        await tester.pump();
        await tester.pumpAndSettle();
      } else {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getCenter(grip).dy, lessThan(rest - 2));
      expectConcealed(tester);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('reduced motion keeps a static hint and accessible reveal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(
          accessibleNavigation: false,
          disableAnimations: true,
        );
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final semantics = tester.ensureSemantics();
    final session = await startCard(tester);
    await tester.pumpAndSettle();
    final rest = tester.getCenter(grip).dy;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getCenter(grip).dy, rest);
      expectConcealed(tester);
    }
    expect(find.text('Hochziehen und halten'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_double_arrow_up_rounded), findsOneWidget);
    final action = tester.getSemantics(
      find.byKey(const ValueKey('secret-peek-action')),
    );
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        nodeId: action.id,
        viewId: tester.view.viewId,
        type: SemanticsAction.tap,
      ),
    );
    await tester.pump();
    expect(session.round!.canAdvanceCard, isTrue);
    expect(
      find.byKey(const ValueKey('secret-curtain-opening')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });

  testWidgets('partial drag immediately ends hints until the next card', (
    tester,
  ) async {
    final session = await startCard(tester);
    final first = session.round!.currentPlayer;
    final rest = tester.getCenter(grip).dy;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.getCenter(grip).dy, lessThan(rest - 2));
    final partial = await tester.startGesture(tester.getCenter(grip));
    await partial.moveBy(const Offset(0, -30));
    await tester.pump();
    final held = tester.getCenter(grip).dy;
    await tester.pump(const Duration(seconds: 4));
    expect(tester.getCenter(grip).dy, held);
    await partial.moveBy(const Offset(0, -10));
    await tester.pump();
    expect(tester.getCenter(grip).dy, closeTo(held - 10, .01));
    await partial.up();
    await tester.pumpAndSettle();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getCenter(grip).dy, closeTo(rest, .01));
      expectConcealed(tester);
    }
    expect(session.round!.currentPlayer, first);
    expect(session.round!.canAdvanceCard, isFalse);
    final full = await openCurtain(tester);
    await full.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(session.round!.currentPlayer, isNot(first));
    // The 500-ms avatar entrance must finish before the two-second wait.
    final nextRest = tester.getCenter(grip).dy;
    final avatar = find.byKey(const ValueKey('curtain-avatar'));
    await tester.pump();
    // Cross the completion frame, avoiding floating-point boundary rounding.
    await tester.pump(const Duration(milliseconds: 501));
    final avatarRest = tester.getCenter(avatar).dy;
    await tester.pump(const Duration(milliseconds: 1999));
    expect(tester.getCenter(grip).dy, nextRest);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 250));
    final lift = nextRest - tester.getCenter(grip).dy;
    expect(lift, inExclusiveRange(2, 20));
    expect(tester.getCenter(avatar).dy, closeTo(avatarRest - lift, .01));
    expectConcealed(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'closed card tugs after two seconds without revealing its secret',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final session = await startCard(tester);
      final person = session.round!.currentPlayer;
      final rest = tester.getCenter(grip).dy;
      await tester.pump(const Duration(milliseconds: 1999));
      expect(tester.getCenter(grip).dy, rest);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getCenter(grip).dy, inExclusiveRange(rest - 20, rest - 2));
      expectConcealed(tester);
      expect(session.round!.canAdvanceCard, isFalse);
      expect(session.round!.currentPlayer, person);
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.getCenter(grip).dy, closeTo(rest, .01));
      await tester.pump(const Duration(milliseconds: 3399));
      expect(tester.getCenter(grip).dy, closeTo(rest, .01));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getCenter(grip).dy, lessThan(rest - 2));
      expectConcealed(tester);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );
}
