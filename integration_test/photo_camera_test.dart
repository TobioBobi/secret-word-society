import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secret_word_society/l10n/app_localizations.dart';
import 'package:secret_word_society/ui/party_theme.dart';
import 'package:secret_word_society/ui/photo_editor.dart';

import '../test/support/tap_when_stable.dart';

// Local Android hardware smoke test. Grant CAMERA before running; emulator
// virtual-scene output is not a substitute for a real selfie acceptance test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('front camera, oval, capture, interruption and cancel', (
    tester,
  ) async {
    Future<void> waitFor(bool Function() ready) async {
      for (var i = 0; i < 150 && !ready(); i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(ready(), isTrue);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPartyTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<Object?>(
                  builder: (_) => const PhotoEditor(name: 'Anna'),
                ),
              ),
              child: const Text('Open photo'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open photo'));
    await tester.pumpAndSettle();
    await waitFor(() => find.byType(CameraPreview).evaluate().isNotEmpty);
    expect(find.byKey(const ValueKey('photo-face-guide')), findsOneWidget);
    expect(
      tester
          .widget<CameraPreview>(find.byType(CameraPreview))
          .controller
          .description
          .lensDirection,
      CameraLensDirection.front,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CameraPreview), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await waitFor(() => find.byType(CameraPreview).evaluate().isNotEmpty);
    await tapWhenStable(
      tester,
      find.text('Foto aufnehmen'),
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await waitFor(
      () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
    );
    // Virtual camera normally has no human face; either a clear retry message
    // or a valid result must be shown, never a stuck capture spinner.
    expect(
      find.text('Übernehmen').evaluate().isNotEmpty ||
          find.textContaining('Kein Gesicht erkannt').evaluate().isNotEmpty ||
          find.textContaining('Mehrere Gesichter').evaluate().isNotEmpty ||
          find.textContaining('Gesicht nicht deutlich').evaluate().isNotEmpty,
      isTrue,
    );
    await tapWhenStable(
      tester,
      find.text('Abbrechen'),
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Open photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
