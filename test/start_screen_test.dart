import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart' show addName;

void main() {
  testWidgets('start actions remain keyboard accessible at large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    for (final label in ['Spielen', 'Spielanleitung', 'Einstellungen']) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.text(label));
      expect(
        node,
        matchesSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          isFocused: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getRect(find.text(label)).center.dy,
        inExclusiveRange(0, 568),
      );
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Datenschutz und Lizenzen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('reduced motion keeps the pressed start action in place', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final play = find.text('Spielen');
    final resting = tester.getCenter(play);
    final press = await tester.startGesture(resting);
    await tester.pumpAndSettle();
    expect(tester.getCenter(play), resting);
    await press.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets('start action sinks onto its paper shadow while pressed', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final play = find.text('Spielen');
    final resting = tester.getCenter(play);
    final press = await tester.startGesture(resting);
    await tester.pumpAndSettle();
    expect(tester.getCenter(play).dy, greaterThan(resting.dy));
    await press.cancel();
    await tester.pumpAndSettle();
    expect(tester.getCenter(play), resting);
  });

  testWidgets('guide opens directly below Play and scrolls to the result', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();
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
    await tester.pumpAndSettle();
    await tester.tap(guide);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Rollenverteilung'), 150);
    await tester.scrollUntilVisible(find.text('Popcorn').first, 150);
    await tester.scrollUntilVisible(find.text('Kino'), 150);
    expect(find.bySemanticsLabel(RegExp(r'Cleo[\s\S]*Kino')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Hinweise geben'), 150);
    await tester.scrollUntilVisible(find.text('Filmpause').first, 150);
    expect(
      find.bySemanticsLabel(RegExp(r'Cleo[\s\S]*Filmpause')).first,
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Verdacht bestätigen'), 150);
    await tester.scrollUntilVisible(find.text('Die Gruppe gewinnt.'), 150);
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(guide, findsOneWidget);
    semantics.dispose();
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
