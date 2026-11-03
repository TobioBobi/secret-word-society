import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../game/player_photo.dart';
import '../game/photo_effects.dart';
export '../game/photo_effects.dart';

/// Never persists a profile. Capture files and detector input are deleted even
/// on errors; retained source and result live only in the session's memory.
class PhotoProcessing {
  Future<PhotoSource> prepare(String capturePath) async {
    final capture = File(capturePath);
    Directory? scratch;
    FaceDetector? detector;
    try {
      late Uint8List bytes;
      try {
        bytes = await compute(normalizePhoto, await capture.readAsBytes());
      } catch (_) {
        throw const PhotoProblem('decode');
      }
      scratch = await capture.parent.createTemp('sws-photo-');
      final input = await File('${scratch.path}/face.jpg').writeAsBytes(bytes);
      detector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      late List<Face> faces;
      try {
        faces = await detector.processImage(
          InputImage.fromFilePath(input.path),
        );
      } on PlatformException {
        throw const PhotoProblem('detection');
      }
      if (faces.length != 1) {
        throw PhotoProblem(faces.isEmpty ? 'noFace' : 'manyFaces');
      }
      final face = faces.single;
      final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
      final left = face.landmarks[FaceLandmarkType.leftEye]?.position;
      final right = face.landmarks[FaceLandmarkType.rightEye]?.position;
      if (nose == null || left == null || right == null) {
        throw const PhotoProblem('landmarks');
      }
      final box = face.boundingBox;
      final mouthLeft = face.landmarks[FaceLandmarkType.leftMouth]?.position;
      final mouthRight = face.landmarks[FaceLandmarkType.rightMouth]?.position;
      return PhotoSource(
        bytes,
        [box.left, box.top, box.width, box.height],
        [nose.x.toDouble(), nose.y.toDouble()],
        [
          [left.x.toDouble(), left.y.toDouble()],
          [right.x.toDouble(), right.y.toDouble()],
        ],
        mouth: mouthLeft != null && mouthRight != null
            ? [
                (mouthLeft.x + mouthRight.x) / 2,
                (mouthLeft.y + mouthRight.y) / 2,
              ]
            : null,
      );
    } finally {
      try {
        await detector?.close();
      } finally {
        try {
          if (await capture.exists()) await capture.delete();
        } finally {
          if (scratch != null && await scratch.exists()) {
            await scratch.delete(recursive: true);
          }
        }
      }
    }
  }

  Future<PlayerPhoto> render(
    PhotoSource source,
    PhotoEffect effect, {
    PhotoVariation? variation,
  }) async {
    final chosen = variation ?? PhotoVariation.random(Random());
    return PlayerPhoto(
      source,
      await compute(renderPhotoVariant, (source, effect, chosen)),
      effect,
      variation: chosen,
    );
  }
}
