import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'player_photo.dart';

Uint8List normalizePhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const PhotoProblem('decode');
  // Bake EXIF before detection. Explicit horizontal flip gives the accepted
  // selfie the same handedness as the front camera's mirrored preview.
  final upright = img.bakeOrientation(decoded);
  final scaled = img.copyResize(
    upright,
    width: upright.width >= upright.height ? 768 : null,
    height: upright.height > upright.width ? 768 : null,
  );
  return img.encodeJpg(img.flipHorizontal(scaled), quality: 90);
}

Uint8List renderPhoto((PhotoSource, PhotoEffect) request) {
  final (source, effect) = request;
  final original = img.decodeJpg(source.bytes)!;
  final output = original.clone();
  final [left, top, width, height] = source.face;
  final cx = left + width / 2;
  final cy = top + height / 2;
  // Inverse mapping always samples the pristine original, including both eyes.
  for (final pixel in output) {
    var x = pixel.x.toDouble();
    var y = pixel.y.toDouble();
    void bulge(List<double> center, double radius, double strength) {
      final dx = x - center[0], dy = y - center[1];
      final distance = sqrt(dx * dx + dy * dy) / radius;
      if (distance < 1) {
        final factor = 1 - strength * pow(1 - distance * distance, 2);
        x = center[0] + dx * factor;
        y = center[1] + dy * factor;
      }
    }

    switch (effect) {
      case PhotoEffect.nose:
        bulge(source.nose, width * .38, .68);
      case PhotoEffect.eyes:
        for (final eye in source.eyes) {
          bulge(eye, width * .25, .62);
        }
      case PhotoEffect.wide:
        final d =
            pow((x - cx) / (width * .85), 2) +
            pow((y - cy) / (height * .75), 2);
        if (d < 1) x = cx + (x - cx) * (1 - .42 * pow(1 - d, 2));
      case PhotoEffect.swirl:
        final dx = x - cx, dy = y - cy;
        final d = sqrt(
          pow(dx / (width * .65), 2) + pow(dy / (height * .65), 2),
        );
        if (d < 1) {
          final angle = 1.8 * pow(1 - d, 2);
          x = cx + dx * cos(angle) - dy * sin(angle);
          y = cy + dx * sin(angle) + dy * cos(angle);
        }
    }
    pixel.set(
      original.getPixelInterpolate(
        x.clamp(0, original.width - 1).toDouble(),
        y.clamp(0, original.height - 1).toDouble(),
        interpolation: img.Interpolation.linear,
      ),
    );
  }
  // Square face-centered avatar, with generous framing; no hard boundary at
  // the distortion radius. Keep the whole result bounded for all player views.
  final side = min(
    min(original.width, original.height),
    (max(width, height) * 1.65).round(),
  );
  final cropped = img.copyCrop(
    output,
    x: (cx - side / 2).round().clamp(0, original.width - side),
    y: (cy - side / 2).round().clamp(0, original.height - side),
    width: side,
    height: side,
  );
  return img.encodeJpg(
    img.copyResize(cropped, width: 384, height: 384),
    quality: 88,
  );
}
