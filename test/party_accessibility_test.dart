import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart'
    show readyGroup, showStart, tapVisible, testCatalog, expectConcealed;

Future<void> _checkAndroidControls(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final largeText in [false, true]) {
    testWidgets(
      'Android controls and contrast through every phase, large=$largeText',
      (tester) async {
        tester.view.physicalSize = largeText
            ? const Size(320, 568)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = largeText ? 2 : 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();
        try {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          var now = DateTime.utc(2026, 10, 25);
          await tester.pumpWidget(
            MyApp(catalogLoader: () async => testCatalog, now: () => now),
          );
          await tester.pumpAndSettle();
          await _checkAndroidControls(tester);
          await readyGroup(tester);
          await showStart(tester);
          await _checkAndroidControls(tester);
          await tapVisible(tester, 'Runde starten');
          String? imposter;
          for (final name in ['Anna', 'Ben', 'Cem']) {
            expectConcealed(tester);
            await _checkAndroidControls(tester);
            await tapVisible(tester, 'Geheimnis kurz ansehen');
            if (find.text('Du bist der Imposter').evaluate().isNotEmpty) {
              imposter = name;
            }
            await tapVisible(tester, 'Gruppe bearbeiten');
            expectConcealed(tester);
            await _checkAndroidControls(tester);
            await tapVisible(tester, 'Weiterspielen');
            await tapVisible(tester, 'Geheimnis kurz ansehen');
            await tester.ensureVisible(
              find.text(name == imposter ? 'Kino' : 'Popcorn'),
            );
            await tester.pumpAndSettle();
            await _checkAndroidControls(tester);
            await tapVisible(tester, 'Weiter');
          }
          await _checkAndroidControls(tester);
          await tapVisible(tester, '10 Sekunden starten');
          await _checkAndroidControls(tester);
          now = now.add(const Duration(seconds: 10));
          await tester.pump(const Duration(milliseconds: 250));
          await tester.pumpAndSettle();
          await _checkAndroidControls(tester);
          final suspect = largeText
              ? ['Anna', 'Ben', 'Cem'].firstWhere((name) => name != imposter)
              : imposter!;
          await tapVisible(tester, suspect);
          await tester.ensureVisible(find.text('$suspect verdächtigen'));
          await tester.pumpAndSettle();
          await _checkAndroidControls(tester);
          await tapVisible(tester, '$suspect verdächtigen');
          expectConcealed(tester);
          final countdown = tester.getRect(find.text('3'));
          expect(countdown.top, greaterThanOrEqualTo(0));
          expect(
            countdown.bottom,
            lessThanOrEqualTo(tester.view.physicalSize.height),
          );
          await _checkAndroidControls(tester);
          now = now.add(const Duration(seconds: 3));
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
          await _checkAndroidControls(tester);
          await tester.scrollUntilVisible(
            find.text('Noch eine Runde'),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(find.text('Noch eine Runde'));
          await tester.pumpAndSettle();
          await _checkAndroidControls(tester);
          await tapVisible(tester, 'Noch eine Runde');
          expectConcealed(tester);
          expect(find.text('Person 1 von 3'), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'landscape at 200% text keeps cards and dialog actions reachable',
    (tester) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(MyApp(catalogLoader: () async => testCatalog));
      await readyGroup(tester);
      await showStart(tester);
      await tapVisible(tester, 'Runde starten');
      await tapVisible(tester, 'Geheimnis kurz ansehen');
      await tapVisible(tester, 'Gruppe bearbeiten');
      expectConcealed(tester);
      // The dialog has its own scrollable body; buttons must fit outside it.
      await tester.tap(find.text('Weiterspielen'));
      await tester.pumpAndSettle();
      expectConcealed(tester);
      await tapVisible(tester, 'Gruppe bearbeiten');
      await tester.tap(find.text('Runde verlassen'));
      await tester.pumpAndSettle();
      expect(find.text('3 Personen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
