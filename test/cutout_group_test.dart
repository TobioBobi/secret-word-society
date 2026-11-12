import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart'
    show pumpPreparation, addName, tapVisible, testCatalog;

void main() {
  testWidgets('long group names have readable width at 200 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpPreparation(
      tester,
      MyApp(catalogLoader: () async => testCatalog),
    );
    const name = 'Alexandra Maria von Sonnenberg';
    await addName(tester, name);
    await tester.ensureVisible(find.text(name));
    await tester.pumpAndSettle();
    // A name must have room for words, rather than a column of single letters.
    expect(tester.getSize(find.text(name)).width, greaterThanOrEqualTo(160));
    await tapVisible(tester, name);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    final field = find.byType(TextField).last;
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    final viewport = tester.getRect(
      find
          .ancestor(of: field, matching: find.byType(SingleChildScrollView))
          .first,
    );
    final input = tester.getRect(field);
    expect(input.top, greaterThanOrEqualTo(viewport.top));
    expect(input.bottom, lessThanOrEqualTo(viewport.bottom));
    await tester.enterText(find.byType(TextField).last, 'Alexandra Maria');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Übernehmen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();
    expect(find.text('Alexandra Maria'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
