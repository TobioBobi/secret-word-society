import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'player_photo.dart';
import 'photo_looks.dart';

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

/// Deterministic entrypoint: the same source, effect and variation give the same
/// result. UI randomness never enters the pixel loop or the source image.
Uint8List renderPhoto(
  (PhotoSource, PhotoEffect) request, {
  PhotoVariation variation = const PhotoVariation(),
}) => renderPhotoVariant((request.$1, request.$2, variation));

Uint8List renderPhotoVariant(
  (PhotoSource, PhotoEffect, PhotoVariation) request,
) {
  final (source, effect, variation) = request;
  final strength = variation.strength;
  if (!strength.isFinite ||
      strength < PhotoVariation.minimumStrength ||
      strength > PhotoVariation.maximumStrength) {
    throw ArgumentError.value(strength, 'strength');
  }
  final original = img.decodeJpg(source.bytes)!;
  final output = original.clone();
  final [left, top, width, height] = source.face;
  final cx = left + width / 2;
  final cy = top + height / 2;
  final mouth = source.mouthCenter;
  final cheekY = (source.nose[1] + mouth[1]) / 2;
  final side = variation.mirrorRight ? 1.0 : -1.0;
  final eyeAxis = (source.eyes[0][0] + source.eyes[1][0]) / 2;

  // Smooth inverse maps; every pixel samples the pristine source once, even
  // when a recipe combines eyes, mouth and jaw. No cumulative reroll damage.
  final decorated = effect.index > PhotoEffect.fisheye.index;
  final distortion = effect.distortion;
  if (distortion != null) {
    for (final pixel in output) {
      var x = pixel.x.toDouble();
      var y = pixel.y.toDouble();
      double falloff(double centerX, double centerY, double rx, double ry) {
        final dx = (x - centerX) / rx, dy = (y - centerY) / ry;
        final d = dx * dx + dy * dy;
        return d < 1 ? (1 - d) * (1 - d) : 0;
      }

      void scaleAt(
        double centerX,
        double centerY,
        double rx,
        double ry,
        double scaleX,
        double scaleY,
      ) {
        final weight = falloff(centerX, centerY, rx, ry);
        x = centerX + (x - centerX) * (1 + (scaleX - 1) * weight);
        y = centerY + (y - centerY) * (1 + (scaleY - 1) * weight);
      }

      void bulge(List<double> center, double radius, double amount) =>
          scaleAt(center[0], center[1], radius, radius, 1 - amount, 1 - amount);
      void bigEyes(double amount) {
        for (final eye in source.eyes) {
          bulge(eye, width * .25, amount);
        }
      }

      switch (distortion) {
        case PhotoEffect.nose:
          bulge(source.nose, width * .38, .68 * strength);
        case PhotoEffect.eyes:
          bigEyes(.62 * strength);
        case PhotoEffect.wide:
          scaleAt(cx, cy, width * .85, height * .75, 1 - .42 * strength, 1);
        case PhotoEffect.swirl:
          final dx = x - cx, dy = y - cy;
          final d = sqrt(
            pow(dx / (width * .65), 2) + pow(dy / (height * .65), 2),
          );
          if (d < 1) {
            final angle = 1.8 * strength * (1 - d) * (1 - d);
            x = cx + dx * cos(angle) - dy * sin(angle);
            y = cy + dx * sin(angle) + dy * cos(angle);
          }
        case PhotoEffect.alien:
          bigEyes(.72 * strength);
          scaleAt(
            mouth[0],
            mouth[1],
            width * .34,
            height * .18,
            1 + .65 * strength,
            1 + .3 * strength,
          );
          scaleAt(
            cx,
            top + height * .86,
            width * .7,
            height * .35,
            1 + .55 * strength,
            1,
          );
        case PhotoEffect.cheeks:
          bulge([cx - width * .29, cheekY], width * .38, .57 * strength);
          bulge([cx + width * .29, cheekY], width * .38, .57 * strength);
          scaleAt(
            mouth[0],
            mouth[1],
            width * .30,
            height * .17,
            1 + .55 * strength,
            1 + .3 * strength,
          );
        case PhotoEffect.grin:
          scaleAt(
            mouth[0],
            mouth[1],
            width * .57,
            height * .25,
            1 - .68 * strength,
            1 - .06 * strength,
          );
        case PhotoEffect.egghead:
          scaleAt(
            cx,
            cy,
            width * .95,
            height * 1.05,
            1 + .30 * strength,
            1 - .40 * strength,
          );
        case PhotoEffect.squashed:
          scaleAt(
            cx,
            cy,
            width * .95,
            height * 1.05,
            1 - .40 * strength,
            1 + .42 * strength,
          );
        case PhotoEffect.asymmetric:
          final weight = falloff(cx, cy, width * .8, height * .8);
          final dx = x - cx;
          // Smoothly change scale across the midline, without a hard split.
          final balance = dx / sqrt(dx * dx + width * width * .04);
          x = cx + dx * (1 - .40 * strength * side * balance * weight);
          y -= height * .18 * strength * side * balance * weight;
          final eye = source.eyes[variation.mirrorRight ? 1 : 0];
          bulge(eye, width * .25, .45 * strength);
        case PhotoEffect.mini:
          scaleAt(
            cx,
            cy + height * .04,
            width * .66,
            height * .57,
            1 + .90 * strength,
            1 + .90 * strength,
          );
        case PhotoEffect.mirror:
          // Keep an exact left/left or right/right reflection; the gentle prior
          // horizontal warp varies the strength without dissolving the mirror.
          scaleAt(eyeAxis, cy, width * .8, height * .8, 1 - .20 * strength, 1);
          x = eyeAxis + side * (x - eyeAxis).abs();
        case PhotoEffect.jelly:
          final weight = falloff(cx, cy, width * .8, height * .85);
          final originalX = x;
          x +=
              width *
              .18 *
              strength *
              sin((y - top) / height * pi * 3) *
              weight;
          y +=
              height *
              .06 *
              strength *
              sin((originalX - left) / width * pi * 3) *
              weight;
        case PhotoEffect.fisheye:
          scaleAt(
            cx,
            cy,
            width * .72,
            height * .82,
            1 - .72 * strength,
            1 - .72 * strength,
          );
        default:
          break;
      }
      pixel.set(
        original.getPixelInterpolate(
          x.clamp(0, original.width - 1).toDouble(),
          y.clamp(0, original.height - 1).toDouble(),
          interpolation: img.Interpolation.linear,
        ),
      );
    }
  }
  final cropSide = min(
    min(original.width, original.height),
    (max(width, height) * 1.65).round(),
  );
  final cropX = (cx - cropSide / 2).round().clamp(0, original.width - cropSide);
  final cropY = (cy - cropSide / 2).round().clamp(
    0,
    original.height - cropSide,
  );
  final cropped = img.copyCrop(
    output,
    x: cropX,
    y: cropY,
    width: cropSide,
    height: cropSide,
  );
  final result = img.copyResize(cropped, width: 384, height: 384);
  if (decorated) {
    applyPhotoLook(result, source, effect, variation, cropX, cropY, cropSide);
  }
  return img.encodeJpg(result, quality: 88);
}
