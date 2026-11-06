import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart' show addName;

void main() {
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
