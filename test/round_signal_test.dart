import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';
import 'package:secret_word_society/platform/round_signal.dart';
import 'package:secret_word_society/ui/time_up_card.dart';

import 'widget_test.dart'
    show readyGroup, showStart, tapVisible, expectConcealed, testCatalog;

void main() {
  final calls = <MethodCall>[];
  var now = DateTime.utc(2026, 10, 31, 12);
  var backgroundAllowed = true;

  setUp(() {
    calls.clear();
    now = DateTime.utc(2026, 10, 31, 12);
    backgroundAllowed = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RoundSignal.channel, (call) async {
          calls.add(call);
          if (call.method == 'backgroundAllowed') return backgroundAllowed;
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RoundSignal.channel, null);
  });

  Future<void> distribute(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tapVisible(tester, 'Geheimnis kurz ansehen');
      await tapVisible(tester, 'Weiter');
    }
  }

  Future<void> ready(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MyApp(catalogLoader: () async => testCatalog, now: () => now),
    );
    await readyGroup(tester);
    await showStart(tester);
    await tapVisible(tester, 'Runde starten');
    await distribute(tester);
  }

  Future<void> expire(WidgetTester tester) async {
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
  }

  testWidgets(
    'one deadline and signal per round, no replay on return or rebuild',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await ready(tester);
      await tapVisible(tester, '10 Sekunden starten');
      final arm = calls.singleWhere((c) => c.method == 'arm');
      expect(
        arm.arguments['deadlineMillis'],
        now.add(const Duration(seconds: 10)).millisecondsSinceEpoch,
      );
      expect(calls.where((c) => c.method == 'finish'), isEmpty);
      await expire(tester);
      expect(find.text('Zeit ist um!'), findsOneWidget);
      expect(
        tester.widget<TimeUpCard>(find.byType(TimeUpCard)).animate,
        isTrue,
      );
      expectConcealed(tester);
      final finish = calls.singleWhere((c) => c.method == 'finish');
      expect(finish.arguments['token'], arm.arguments['token']);
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
      }
      await tester.pump(const Duration(minutes: 2));
      expect(calls.where((c) => c.method == 'finish'), hasLength(1));
      await tapVisible(tester, 'Anna');
      await tapVisible(tester, 'Anna verdächtigen');
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Noch eine Runde');
      await distribute(tester);
      await tapVisible(tester, '10 Sekunden starten');
      await expire(tester);
      await tester.pumpAndSettle();
      final arms = calls.where((c) => c.method == 'arm').toList();
      final finishes = calls.where((c) => c.method == 'finish').toList();
      expect(arms, hasLength(2));
      expect(finishes, hasLength(2));
      expect(arms[1].arguments['token'], isNot(arms[0].arguments['token']));
      expect(finishes[1].arguments['token'], arms[1].arguments['token']);
      semantics.dispose();
    },
  );

  testWidgets(
    'late background return stays silent and shows a static end card',
    (tester) async {
      await ready(tester);
      await tapVisible(tester, '10 Sekunden starten');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Zeit ist um!'), findsOneWidget);
      expect(
        tester.widget<TimeUpCard>(find.byType(TimeUpCard)).animate,
        isFalse,
      );
      expect(calls.where((c) => c.method == 'finish'), isEmpty);
      expectConcealed(tester);
    },
  );

  testWidgets('abort cancels alarm and abandoned deadline cannot fire', (
    tester,
  ) async {
    await ready(tester);
    await tapVisible(tester, '10 Sekunden starten');
    await tapVisible(tester, 'Gruppe bearbeiten');
    await tapVisible(tester, 'Runde verlassen');
    expect(calls.last.method, 'cancel');
    now = now.add(const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 20));
    expect(calls.where((c) => c.method == 'finish'), isEmpty);
    expect(find.text('Zeit ist um!'), findsNothing);
  });

  testWidgets('background permission is explained, requested and refreshed', (
    tester,
  ) async {
    backgroundAllowed = false;
    await ready(tester);
    expect(find.text('Hintergrundton erlauben'), findsOneWidget);
    await tapVisible(tester, 'Hintergrundton erlauben');
    expect(calls.where((c) => c.method == 'requestBackground'), hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    backgroundAllowed = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Hintergrundton erlauben'), findsNothing);
  });

  testWidgets('reduced motion uses a static, readable signal at 200% text', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await ready(tester);
    await tapVisible(tester, '10 Sekunden starten');
    await expire(tester);
    await tester.ensureVisible(find.byType(TimeUpCard));
    await tester.pumpAndSettle();
    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(TimeUpCard),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.getMaxScaleOnAxis(), 1);
    expect(find.text('Zeit ist um!'), findsOneWidget);
    expectConcealed(tester);
    expect(tester.takeException(), isNull);
  });
}
