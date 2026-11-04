import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:image/image.dart' as img;
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/game/player_photo.dart';
import 'package:secret_word_society/l10n/app_localizations.dart';
import 'package:secret_word_society/platform/photo_processing.dart';
import 'package:secret_word_society/ui/photo_editor.dart';
import 'package:secret_word_society/ui/party_theme.dart';
import 'package:secret_word_society/main.dart';
import 'package:secret_word_society/ui/player_avatar.dart';

import 'widget_test.dart' show testCatalog, readyGroup, tapVisible, showStart;

PhotoSource source() {
  final image = img.Image(width: 240, height: 320);
  for (final p in image) {
    p.r = p.x;
    p.g = p.y % 256;
    p.b = (p.x + p.y) % 256;
  }
  return PhotoSource(img.encodeJpg(image), [50, 65, 140, 160], [120, 145], [
    [85, 110],
    [155, 110],
  ]);
}

class DeferredProcessing extends PhotoProcessing {
  final result = Completer<PlayerPhoto>();
  PhotoSource? input;
  PhotoEffect? effect;
  @override
  Future<PlayerPhoto> render(
    PhotoSource source,
    PhotoEffect effect, {
    PhotoVariation? variation,
  }) {
    input = source;
    this.effect = effect;
    return result.future;
  }
}

class UnavailableCamera extends CameraPlatform {
  UnavailableCamera(this.denied);
  final bool denied;
  @override
  Future<List<CameraDescription>> availableCameras() async {
    if (denied) throw CameraException('CameraAccessDenied', 'Denied');
    return [];
  }
}

void main() {
  test('selectable recipes exclude wizard motifs and always pair filters', () {
    expect(
      PhotoEffect.values.any((e) => e.name.toLowerCase().contains('wizard')),
      isFalse,
    );
    final filters = PhotoEffect.values.where((e) => e.hasFilter).toList();
    expect(filters, hasLength(9));
    for (final effect in filters) {
      expect(
        effect.distortion != null || effect.accessory != null,
        isTrue,
        reason: '${effect.name} must never render as a filter alone',
      );
    }
    expect(PhotoEffect.green.distortion, PhotoEffect.alien);
    expect(PhotoEffect.ice.distortion, PhotoEffect.eyes);
    expect(PhotoEffect.pink.distortion, PhotoEffect.cheeks);
    expect(PhotoEffect.mono.distortion, PhotoEffect.fisheye);
    expect(PhotoEffect.comic.distortion, PhotoEffect.grin);
    expect(PhotoEffect.sepia.accessory, PhotoEffect.moustache);
    expect(PhotoEffect.retro.accessory, PhotoEffect.sunglasses);
    expect(PhotoEffect.sunset.accessory, PhotoEffect.partyHat);
  });
  test('color looks and accessories preserve the distortion photo crop', () {
    final original = source();
    // Existing distortion framing for this 240x320 source is x=0,y=25,side=240.
    final reference = img.copyResize(
      img.copyCrop(
        img.decodeJpg(original.bytes)!,
        x: 0,
        y: 25,
        width: 240,
        height: 240,
      ),
      width: 384,
      height: 384,
    );
    final mono = img.decodeJpg(renderPhoto((original, PhotoEffect.mono)))!;
    final accessory = img.decodeJpg(
      renderPhoto((original, PhotoEffect.clown)),
    )!;
    for (final x in [16, 64, 320, 368]) {
      for (final y in [16, 64, 320, 368]) {
        final expected = reference.getPixel(x, y);
        expect(mono.getPixel(x, y).r, closeTo(img.getLuminance(expected), 4));
        final actual = accessory.getPixel(x, y);
        expect(actual.r, closeTo(expected.r, 4));
        expect(actual.g, closeTo(expected.g, 4));
        expect(actual.b, closeTo(expected.b, 4));
      }
    }
  });
  test(
    'clown nose follows source landmarks with clamped crop and head tilt',
    () {
      final original = source();
      for (final slope in [-.5, 0.0, .5]) {
        final tilted = PhotoSource(
          original.bytes,
          [10, 0, 140, 160],
          [80, 80],
          [
            [45, 45 - slope * 35],
            [115, 45 + slope * 35],
          ],
          mouth: [80, 110],
        );
        final image = img.decodeJpg(renderPhoto((tilted, PhotoEffect.clown)))!;
        const side = 240;
        const cropX = 0;
        const cropY = 0;
        final x = ((80 - cropX) * 384 / side).round();
        final y = ((80 - cropY) * 384 / side).round();
        final pixel = image.getPixel(x, y);
        expect(pixel.r, greaterThan(200));
        expect(pixel.g, lessThan(100));
        expect(pixel.b, lessThan(120));
      }
    },
  );
  test('monochrome remains grayscale at both random strength limits', () {
    for (final strength in [.75, 1.25]) {
      final image = img.decodeJpg(
        renderPhoto((
          source(),
          PhotoEffect.mono,
        ), variation: PhotoVariation(strength: strength)),
      )!;
      for (final p in image) {
        expect((p.r - p.g).abs(), lessThanOrEqualTo(2));
        expect((p.b - p.g).abs(), lessThanOrEqualTo(2));
      }
    }
  });
  testWidgets('preview can be accepted immediately after an inactive frame', (
    tester,
  ) async {
    final original = source();
    final photo = PlayerPhoto(
      original,
      renderPhoto((original, PhotoEffect.eyes)),
      PhotoEffect.eyes,
    );
    PlayerPhoto? accepted;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                accepted = await Navigator.of(context).push<PlayerPhoto>(
                  MaterialPageRoute(
                    builder: (_) => PhotoEditor(name: 'Anna', initial: photo),
                  ),
                );
              },
              child: const Text('Open photo'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open photo'));
    await tester.pumpAndSettle();
    final accept = find.widgetWithText(FilledButton, 'Übernehmen');
    await tester.scrollUntilVisible(accept, 150);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester
        .pump(); // Real inactive frame: don't hide the bug by resuming first.
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(accepted, same(photo));
    expect(find.text('Open photo'), findsOneWidget);
  });
  test(
    'random strengths stay in range and both mirror directions are reachable',
    () {
      final random = Random(18);
      final draws = List.generate(1000, (_) => PhotoVariation.random(random));
      expect(
        draws.every(
          (v) =>
              v.strength >= PhotoVariation.minimumStrength &&
              v.strength < PhotoVariation.maximumStrength,
        ),
        isTrue,
      );
      expect(draws.map((v) => v.strength).toSet().length, greaterThan(990));
      expect(draws.map((v) => v.mirrorRight).toSet(), {false, true});
    },
  );
  test('all effects vary with strength without changing the source', () {
    final original = source();
    final before = List<int>.of(original.bytes);
    expect(PhotoEffect.values, hasLength(38));
    for (final effect in PhotoEffect.values) {
      final low = renderPhoto(
        (original, effect),
        variation: const PhotoVariation(
          strength: PhotoVariation.minimumStrength,
        ),
      );
      final high = renderPhoto(
        (original, effect),
        variation: const PhotoVariation(
          strength: PhotoVariation.maximumStrength,
        ),
      );
      expect(low, isNot(orderedEquals(high)), reason: effect.name);
      expect(img.decodeJpg(low)!.width, 384);
      expect(img.decodeJpg(high)!.height, 384);
      expect(original.bytes, before);
    }
    final left = renderPhoto((original, PhotoEffect.mirror));
    final right = renderPhoto((
      original,
      PhotoEffect.mirror,
    ), variation: const PhotoVariation(mirrorRight: true));
    expect(left, isNot(orderedEquals(right)));
  });
  test(
    'native detector failure is distinct from a bad photo and cleans files',
    () async {
      const channel = MethodChannel('google_mlkit_face_detector');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'vision#startFaceDetector') {
          throw PlatformException(
            code: 'error',
            message: 'Native initialization failed',
          );
        }
        return null;
      });
      final directory = await Directory.systemTemp.createTemp(
        'photo-error-test-',
      );
      try {
        final capture = await File('${directory.path}/capture.jpg')
            .writeAsBytes(source().bytes);
        await expectLater(
          PhotoProcessing().prepare(capture.path),
          throwsA(
            isA<PhotoProblem>().having((e) => e.code, 'code', 'detection'),
          ),
        );
        expect(await directory.list().toList(), isEmpty);
        final broken = await File('${directory.path}/broken.jpg')
            .writeAsBytes([1, 2, 3]);
        await expectLater(
          PhotoProcessing().prepare(broken.path),
          throwsA(isA<PhotoProblem>().having((e) => e.code, 'code', 'decode')),
        );
        expect(await directory.list().toList(), isEmpty);
      } finally {
        messenger.setMockMethodCallHandler(channel, null);
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'group photo dice immediately creates a preview from the original',
    (tester) async {
      final original = source();
      final photo = PlayerPhoto(
        original,
        renderPhoto((original, PhotoEffect.nose)),
        PhotoEffect.nose,
      );
      final processing = DeferredProcessing();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoEditor(
            name: 'Anna',
            initial: photo,
            processing: processing,
            rerollInitially: true,
          ),
        ),
      );
      expect(processing.input, same(original));
      expect(processing.effect, isNot(photo.effect));
      processing.result.complete(
        PlayerPhoto(original, photo.bytes, processing.effect!),
      );
      await tester.pumpAndSettle();
      expect(find.text('Übernehmen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'accepted photo appears through voting, result and follow-up; removal restores Cutouts',
    (tester) async {
      var now = DateTime.utc(2026);
      final original = source();
      final photo = PlayerPhoto(
        original,
        renderPhoto((original, PhotoEffect.eyes)),
        PhotoEffect.eyes,
      );
      var cancel = false;
      await tester.pumpWidget(
        MyApp(
          catalogLoader: () async => testCatalog,
          now: () => now,
          photoEditorLauncher: (_, _) async => cancel ? null : photo,
        ),
      );
      await readyGroup(tester);
      final button = find.byTooltip('Foto für Anna');
      await tester.scrollUntilVisible(
        button,
        -150,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      final avatar = tester
          .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
          .avatar;
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      cancel = true;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      await showStart(tester);
      await tapVisible(tester, 'Runde starten');
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      for (var i = 0; i < 3; i++) {
        await tapVisible(tester, 'Weiter');
      }
      await tapVisible(tester, '01:30 starten');
      now = now.add(const Duration(seconds: 90));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      await tapVisible(tester, 'Anna');
      await tapVisible(tester, 'Anna verdächtigen');
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is PlayerAvatarView && identical(w.photo, photo),
        ),
        findsWidgets,
      );
      await tapVisible(tester, 'Noch eine Runde');
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Runde verlassen');
      await tester.scrollUntilVisible(
        find.byTooltip('Foto entfernen'),
        -150,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byTooltip('Foto entfernen'));
      await tester.pumpAndSettle();
      final restored = tester.widget<PlayerAvatarView>(
        find.byType(PlayerAvatarView).first,
      );
      expect(restored.photo, isNull);
      expect(restored.avatar, same(avatar));
      expect(tester.takeException(), isNull);
    },
  );
  for (final denied in [false, true]) {
    testWidgets(
      'missing camera or denied permission remains cancellable: $denied',
      (tester) async {
        final platform = CameraPlatform.instance;
        CameraPlatform.instance = UnavailableCamera(denied);
        addTearDown(() => CameraPlatform.instance = platform);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PhotoEditor(name: 'Anna'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            denied ? 'Kein Kamerazugriff' : 'Keine Frontkamera',
          ),
          findsOneWidget,
        );
        expect(find.text('Abbrechen'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Foto aufnehmen'),
              )
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  test('effects always sample original, are distinct and bounded', () {
    final original = source();
    final before = Uint8List.fromList(original.bytes);
    final results = <String>{};
    for (final effect in PhotoEffect.values) {
      final bytes = renderPhoto((original, effect));
      final image = img.decodeJpg(bytes)!;
      expect((image.width, image.height), (384, 384));
      expect(bytes.length, lessThan(100000));
      expect(renderPhoto((original, effect)), bytes);
      expect(original.bytes, before);
      results.add(bytes.toString());
    }
    expect(results, hasLength(38));
  });

  test('EXIF orientation is baked, mirrored once, metadata removed', () {
    final image = img.Image(width: 100, height: 200);
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: 49,
      y2: 199,
      color: img.ColorRgb8(255, 0, 0),
    );
    img.fillRect(
      image,
      x1: 50,
      y1: 0,
      x2: 99,
      y2: 199,
      color: img.ColorRgb8(0, 0, 255),
    );
    final normal = img.decodeJpg(normalizePhoto(img.encodeJpg(image)))!;
    expect(normal.getPixel(10, 100).b, greaterThan(200));
    image.exif.imageIfd.orientation = 6;
    final rotated = img.decodeJpg(normalizePhoto(img.encodeJpg(image)))!;
    expect((rotated.width, rotated.height), (768, 384));
    expect(rotated.exif.imageIfd.hasOrientation, isFalse);
  });

  test('photo preserves identity and Cutouts through rename and rounds', () {
    final session = GameSession()
      ..addPlayer('Anna')
      ..addPlayer('Ben')
      ..addPlayer('Cem');
    final player = session.players.first;
    final original = source();
    final photo = PlayerPhoto(
      original,
      renderPhoto((original, PhotoEffect.nose)),
      PhotoEffect.nose,
    );
    session.setPhoto(player.id, photo);
    session.renamePlayer(player.id, 'Anni');
    expect(session.players.first.photo, same(photo));
    expect(session.players.first.avatar, same(player.avatar));
    session.startRound(testCatalog);
    expect(session.round!.currentPlayer!.photo, same(photo));
    expect(() => session.setPhoto(player.id, null), throwsStateError);
    while (session.round!.canAdvanceCard) {
      session.hideAndAdvance();
    }
    final now = DateTime.utc(2026);
    session.startDiscussion(now);
    session.advanceTime(now.add(const Duration(minutes: 2)));
    session.selectSuspect(player.id);
    session.confirmSuspect(now);
    session.advanceTime(now.add(const Duration(seconds: 3)));
    expect(session.round!.result!.suspects.single.photo, same(photo));
    session.newRound();
    expect(session.round!.currentPlayer!.photo, same(photo));
    session.returnToGroup();
    session.setPhoto(player.id, null);
    expect(session.players.first.photo, isNull);
    expect(session.players.first.avatar, same(player.avatar));
    session.setPhoto(player.id, photo);
    session.removePlayer(player.id);
    session.addPlayer('Anni');
    expect(session.players.last.photo, isNull);
    expect(GameSession().players, isEmpty);
  });

  for (final interrupt in [false, true]) {
    testWidgets(
      'preview uses original, cancel/interrupt discards pending effect: $interrupt',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final original = source();
        final photo = PlayerPhoto(
          original,
          renderPhoto((original, PhotoEffect.nose)),
          PhotoEffect.nose,
        );
        final processing = DeferredProcessing();
        PlayerPhoto? accepted;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildPartyTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    accepted = await Navigator.push<PlayerPhoto>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoEditor(
                          name: 'Anna',
                          initial: photo,
                          processing: processing,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Effekt würfeln'), 150);
        await tester.tap(find.text('Effekt würfeln'));
        await tester.pump();
        expect(processing.input, same(original));
        expect(processing.effect, isNot(photo.effect));
        if (interrupt) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        } else {
          await tester.scrollUntilVisible(find.text('Abbrechen'), 150);
          await tester.tap(find.text('Abbrechen'));
          await tester.pumpAndSettle();
        }
        processing.result.complete(
          PlayerPhoto(original, photo.bytes, processing.effect!),
        );
        await tester.pumpAndSettle();
        if (interrupt) {
          expect(find.text('Große Nase'), findsNothing);
          await tester.scrollUntilVisible(find.text('Übernehmen'), -120);
          await tester.tap(find.text('Übernehmen'));
          await tester.pumpAndSettle();
          expect(accepted, same(photo));
        } else {
          expect(accepted, isNull);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
