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
    await tester.enterText(find.byType(TextField).last, 'Alexandra Maria');
    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();
    expect(find.text('Alexandra Maria'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
