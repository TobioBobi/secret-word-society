import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart' show addName;

void main() {
  testWidgets(
    'keyboard reaches privacy and licenses and side paths retain the group',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spielen'));
      await tester.pumpAndSettle();
      await addName(tester, 'Anna');
      await tester.enterText(find.byType(TextField), 'Ben');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Einstellungen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Einstellungen'));
      await tester.pumpAndSettle();
      for (final label in ['Datenschutz und Lizenzen', 'Lizenzen']) {
        // Back is first, followed by the existing content action.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.text(label)),
          matchesSemantics(
            label: label,
            isButton: true,
            isFocusable: true,
            isFocused: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        expect(
          tester.getRect(find.text(label)).center.dy,
          inExclusiveRange(0, 568),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 3; i++) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Spielanleitung'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spielanleitung'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Spielen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spielen'));
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Anna'),
        160,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Anna'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'license details keep long names and the last paragraph reachable',
    (tester) async {
      const package = 'Photo capture and face detection (native)';
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks(
          [package],
          '${List.filled(12, 'License paragraph.').join('\n\n')}\n\nEnd of license.',
        );
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Einstellungen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Einstellungen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Datenschutz und Lizenzen'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Lizenzen'), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lizenzen'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(package), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text(package));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(package))
            .didExceedMaxLines,
        isFalse,
      );
      await tester.scrollUntilVisible(find.text('End of license.'), 180);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('End of license.')).bottom,
        lessThanOrEqualTo(568),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Lizenzen'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('privacy heading is fully readable with large system text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Datenschutz und Lizenzen'));
    await tester.pumpAndSettle();
    final heading = tester.renderObject<RenderParagraph>(
      find.text('Datenschutz und Lizenzen'),
    );
    expect(heading.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
