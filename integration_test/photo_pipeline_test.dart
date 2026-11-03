import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:secret_word_society/game/player_photo.dart';
import 'package:secret_word_society/platform/photo_processing.dart';

import 'photo_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('bundled native detector, all effects and temporary cleanup', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp('photo-test-');
    final processing = PhotoProcessing();
    try {
      final input = await File('${directory.path}/capture.jpg')
          .writeAsBytes(base64Decode(photoFixture));
      final source = await processing.prepare(input.path);
      expect(await input.exists(), isFalse);
      expect(await directory.list().toList(), isEmpty);
      // Used for local visual inspection without shipping a diagnostic surface.
      // ignore: avoid_print
      print(
        'PHOTO_LANDMARKS=${jsonEncode([source.face, source.nose, source.eyes])}',
      );
      for (final effect in PhotoEffect.values) {
        final watch = Stopwatch()..start();
        final photo = await processing.render(source, effect);
        expect(img.decodeJpg(photo.bytes)!.width, 384);
        expect(identical(photo.source, source), isTrue);
        expect(
          photo.variation.strength,
          inInclusiveRange(
            PhotoVariation.minimumStrength,
            PhotoVariation.maximumStrength,
          ),
        );
        // ignore: avoid_print
        print(
          'PHOTO_EFFECT=${effect.name}:${watch.elapsedMilliseconds}ms:${photo.bytes.length}bytes',
        );
      }
      final faceImage = img.decodeJpg(base64Decode(photoFixture))!;
      final pair = img.Image(width: 960, height: 480);
      img.compositeImage(pair, faceImage);
      img.compositeImage(pair, faceImage, dstX: 480);
      for (final entry in {
        'manyFaces': pair,
        'noFace': img.Image(width: 480, height: 480),
      }.entries) {
        final file = await File('${directory.path}/capture.jpg')
            .writeAsBytes(img.encodeJpg(entry.value));
        await expectLater(
          processing.prepare(file.path),
          throwsA(isA<PhotoProblem>().having((e) => e.code, 'code', entry.key)),
        );
        expect(await directory.list().toList(), isEmpty);
      }
      final broken = await File('${directory.path}/bad.jpg')
          .writeAsBytes([1, 2, 3]);
      await expectLater(
        processing.prepare(broken.path),
        throwsA(isA<PhotoProblem>()),
      );
      expect(await directory.list().toList(), isEmpty);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
