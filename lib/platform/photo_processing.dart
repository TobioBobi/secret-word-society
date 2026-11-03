import 'dart:io';

import 'package:flutter/foundation.dart';
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
      final bytes = await compute(normalizePhoto, await capture.readAsBytes());
      scratch = await capture.parent.createTemp('sws-photo-');
      final input = await File('${scratch.path}/face.jpg').writeAsBytes(bytes);
      detector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      final faces = await detector.processImage(
        InputImage.fromFilePath(input.path),
      );
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
      return PhotoSource(
        bytes,
        [box.left, box.top, box.width, box.height],
        [nose.x.toDouble(), nose.y.toDouble()],
        [
          [left.x.toDouble(), left.y.toDouble()],
          [right.x.toDouble(), right.y.toDouble()],
        ],
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

  Future<PlayerPhoto> render(PhotoSource source, PhotoEffect effect) async =>
      PlayerPhoto(source, await compute(renderPhoto, (source, effect)), effect);
}
