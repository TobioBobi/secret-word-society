import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';
import 'package:secret_word_society/platform/round_signal.dart';
import 'package:secret_word_society/ui/time_up_card.dart';

import 'widget_test.dart' show readyGroup, showStart, tapVisible, testCatalog;

Future<void> _change(WidgetTester tester, String tooltip) async {
  final button = find.byTooltip(tooltip);
  await tester.scrollUntilVisible(button, 160);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _distribute(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tapVisible(tester, 'Weiter');
  }
}

void main() {
  for (final background in [false, true]) {
    testWidgets(
      'custom duration, signal and follow-up, background=$background',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();
        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(RoundSignal.channel, (call) async {
              calls.add(call);
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(RoundSignal.channel, null),
        );
        var now = DateTime.utc(2026, 11, 1);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpWidget(
          MyApp(catalogLoader: () async => testCatalog, now: () => now),
        );
        await readyGroup(tester);
        await showStart(tester);
        await _change(tester, '30 Sekunden länger');
        expect(find.text('02:00'), findsOneWidget);
        await _change(tester, '30 Sekunden kürzer');
        await _change(tester, '30 Sekunden kürzer');
        await tapVisible(tester, 'Runde starten');
        await _distribute(tester);
        await _change(tester, '30 Sekunden kürzer');
        expect(find.text('00:30'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.ancestor(
                  of: find.byTooltip('30 Sekunden kürzer'),
                  matching: find.byType(IconButton),
                ),
              )
              .onPressed,
          isNull,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await tapVisible(tester, '00:30 starten');
        expect(find.byTooltip('30 Sekunden länger'), findsNothing);
        final arm = calls.singleWhere((call) => call.method == 'arm');
        expect(
          arm.arguments['deadlineMillis'],
          now.add(const Duration(seconds: 30)).millisecondsSinceEpoch,
        );
        now = now.add(const Duration(seconds: 29));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('00:01'), findsOneWidget);
        if (background) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
        }
        now = now.add(Duration(seconds: background ? 10 : 1));
        if (background) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        }
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
        expect(find.text('Zeit ist um!'), findsOneWidget);
        final finish = calls.singleWhere((call) => call.method == 'finish');
        expect(finish.arguments['audible'], !background);
        expect(
          tester.widget<TimeUpCard>(find.byType(TimeUpCard)).animate,
          !background,
        );
        await tapVisible(tester, 'Anna');
        await tapVisible(tester, 'Anna verdächtigen');
        now = now.add(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        await tapVisible(tester, 'Noch eine Runde');
        await _distribute(tester);
        await tester.scrollUntilVisible(find.text('00:30 starten'), 160);
        await tester.pumpAndSettle();
        expect(find.text('00:30'), findsOneWidget);
        await _change(tester, '30 Sekunden länger');
        expect(find.text('01:00'), findsOneWidget);
        await tapVisible(tester, 'Automatisch');
        expect(find.text('01:30'), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets('maximum and reset to automatic in setup', (tester) async {
    await tester.pumpWidget(MyApp(catalogLoader: () async => testCatalog));
    await readyGroup(tester);
    await showStart(tester);
    for (var i = 0; i < 27; i++) {
      await _change(tester, '30 Sekunden länger');
    }
    expect(find.text('15:00'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('30 Sekunden länger'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await _change(tester, '30 Sekunden kürzer');
    expect(find.text('14:30'), findsOneWidget);
    await tapVisible(tester, 'Automatisch');
    expect(find.text('01:30'), findsOneWidget);
    await tapVisible(tester, 'Runde starten');
    await _distribute(tester);
    await tapVisible(tester, '01:30 starten');
    expect(find.text('01:30'), findsOneWidget);
  });
}
