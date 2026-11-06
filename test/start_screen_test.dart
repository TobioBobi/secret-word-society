import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart' show addName;

void main() {
  testWidgets('guide opens directly below Play and scrolls to the result', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final guide = find.widgetWithText(OutlinedButton, 'Spielanleitung');
    expect(
      tester.getTopLeft(guide).dy,
      greaterThan(tester.getBottomLeft(find.text('Spielen')).dy),
    );
    expect(
      tester.getBottomLeft(guide).dy,
      lessThan(tester.getTopLeft(find.text('Einstellungen')).dy),
    );
    await tester.ensureVisible(guide);
    await tester.tap(guide);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Popcorn'), 150);
    await tester.scrollUntilVisible(find.text('Kino'), 150);
    await tester.scrollUntilVisible(find.text('4. Auflösung'), 150);
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(guide, findsOneWidget);
  });

  testWidgets('both back paths preserve the group and name draft', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Secret Word Society'), findsOneWidget);
    await tester.tap(find.text('Spielen'));
    await tester.pumpAndSettle();
    await addName(tester, 'Anna');
    await tester.enterText(find.byType(TextField), 'Ben');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spielen'));
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Spielen'), findsOneWidget);
    await tester.tap(find.text('Spielen'));
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);
  });
  testWidgets('privacy is reached through settings and both back paths work', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Datenschutz und Lizenzen'), findsNothing);

    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Datenschutz und Lizenzen'));
    await tester.pumpAndSettle();
    expect(find.text('Datenschutz und Lizenzen'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Lizenzen'), 200);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Spielen'), findsOneWidget);

    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Spielen'), findsOneWidget);
  });
}
