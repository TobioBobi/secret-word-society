import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/l10n/app_localizations.dart';
import 'package:secret_word_society/ui/party_theme.dart';
import 'package:secret_word_society/ui/secret_curtain.dart';

void main() {
  testWidgets(
    'short secret, role and label retain enlarged text when they fit',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final heights = <double, List<double>>{};
      for (final scale in [1.0, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final focus = FocusNode();
        addTearDown(focus.dispose);
        var revealed = false;
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(scale),
            theme: buildPartyTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, update) => SecretCurtain(
                  title: 'Handy an Anna.',
                  name: 'Anna',
                  headingFocus: focus,
                  hintActive: false,
                  canAdvance: true,
                  onHandoff: () {},
                  onInterrupt: () => update(() => revealed = false),
                  revealed: revealed,
                  concealRevision: 0,
                  onReveal: (_) => update(() => revealed = true),
                  onConceal: () => update(() => revealed = false),
                  secretBuilder: (_, textKey) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Rolle',
                        style: TextStyle(fontSize: 22, height: 1),
                      ),
                      const Text(
                        'Hinweis',
                        style: TextStyle(fontSize: 16, height: 1),
                      ),
                      Text(
                        'Kino',
                        key: textKey,
                        style: const TextStyle(fontSize: 30, height: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester
            .widget<Semantics>(find.byKey(const ValueKey('secret-peek-action')))
            .properties
            .onTap!();
        await tester.pumpAndSettle();
        heights[scale] = [
          for (final text in ['Rolle', 'Hinweis', 'Kino'])
            _paintedTextHeight(tester, text),
        ];
      }
      for (var index = 0; index < 3; index++) {
        expect(heights[2.0]![index], closeTo(heights[1.0]![index] * 2, .1));
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}

double _paintedTextHeight(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final bounds = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      )
      .single
      .toRect();
  return (paragraph.localToGlobal(bounds.bottomRight) -
          paragraph.localToGlobal(bounds.topLeft))
      .dy;
}
