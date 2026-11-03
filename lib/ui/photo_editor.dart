import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/player_photo.dart';
import '../l10n/app_localizations.dart';
import '../platform/photo_processing.dart';
import 'photo_image.dart';
import 'photo_privacy.dart';

class PhotoEditor extends StatefulWidget {
  const PhotoEditor({
    super.key,
    required this.name,
    this.initial,
    this.processing,
    this.rerollInitially = false,
  });
  final String name;
  final PlayerPhoto? initial;
  final PhotoProcessing? processing;
  final bool rerollInitially;

  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditor> with WidgetsBindingObserver {
  CameraController? _camera;
  late final _processing = widget.processing ?? PhotoProcessing();
  late PlayerPhoto? _photo = widget.initial;
  bool _busy = false;
  bool _active = true;
  bool _cameraWanted = false;
  bool _opening = false;
  String? _error;
  int _revision = 0;
  Future<void> _closing = Future.value();

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    WidgetsBinding.instance.addObserver(this);
    if (_photo == null) {
      _cameraWanted = true;
      unawaited(_openCamera());
    } else if (widget.rerollInitially) {
      unawaited(_reroll());
    }
  }

  Future<void> _closeCamera() {
    final camera = _camera;
    _camera = null;
    return _closing = _closing.then((_) async {
      try {
        await camera?.dispose();
      } on CameraException {
        // A platform camera may already be gone after an interruption.
      } on PlatformException {
        // Keep later initialization usable even if native disposal failed.
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permission dialogs cause inactive; do not invalidate initialization there.
    if (state == AppLifecycleState.inactive && !_opening) {
      _active = false;
      _revision++;
      unawaited(_closeCamera());
      setState(() {
        _busy = false;
      });
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _active = false;
      _revision++;
      unawaited(_closeCamera());
      setState(() {
        _busy = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _active = true;
      if (_cameraWanted && !_opening) unawaited(_openCamera());
    }
  }

  Future<void> _openCamera() async {
    if (_opening || !_active || !mounted) return;
    _opening = true;
    final revision = ++_revision;
    setState(() {
      _busy = true;
      _error = null;
    });
    CameraController? camera;
    try {
      await _closeCamera();
      final cameras = await availableCameras();
      final front = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (front.isEmpty) throw const PhotoProblem('noCamera');
      camera = CameraController(
        front.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await camera.initialize();
      await camera.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted || !_active || revision != _revision) {
        await camera.dispose();
        return;
      }
      setState(() {
        _camera = camera;
        _busy = false;
      });
    } catch (error) {
      await camera?.dispose();
      if (mounted && revision == _revision) {
        setState(() {
          _busy = false;
          _error = error is CameraException && error.code.contains('Access')
              ? 'permission'
              : 'noCamera';
        });
      }
    } finally {
      _opening = false;
      if (mounted && _active && _cameraWanted && revision != _revision) {
        unawaited(_openCamera());
      }
    }
  }

  PhotoEffect _nextEffect(PhotoEffect? previous) {
    final choices = PhotoEffect.values.where((e) => e != previous).toList();
    return choices[Random().nextInt(choices.length)];
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (_busy || camera == null || !_active) return;
    final revision = ++_revision;
    setState(() {
      _busy = true;
      _error = null;
    });
    XFile? capture;
    var stage = 'capture';
    try {
      capture = await camera.takePicture();
      if (!mounted || revision != _revision) return;
      stage = 'processing';
      final source = await _processing.prepare(capture.path);
      stage = 'effect';
      final photo = await _processing.render(source, _nextEffect(null));
      if (!mounted || revision != _revision) return;
      _cameraWanted = false;
      await _closeCamera();
      if (mounted && revision == _revision) {
        setState(() {
          _photo = photo;
          _busy = false;
        });
      }
    } catch (error) {
      if (mounted && revision == _revision) {
        setState(() {
          _busy = false;
          _error = error is PhotoProblem ? error.code : stage;
        });
      }
    } finally {
      if (capture != null) {
        final file = File(capture.path);
        if (await file.exists()) await file.delete();
      }
    }
  }

  Future<void> _reroll() async {
    if (_busy || _photo == null || !_active) return;
    final revision = ++_revision;
    final previous = _photo!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = await _processing.render(
        previous.source,
        _nextEffect(previous.effect),
      );
      if (mounted && revision == _revision) {
        setState(() {
          _photo = next;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() {
          _busy = false;
          _error = 'effect';
        });
      }
    }
  }

  @override
  void dispose() {
    _revision++;
    unawaited(SystemChrome.setPreferredOrientations([]));
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_closeCamera());
    if (_photo != null) unawaited(MemoryImage(_photo!.bytes).evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final camera = _camera;
    final photo = _photo;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.photoFor(widget.name)),
        actions: [
          IconButton(
            tooltip: s.privacyAndLicenses,
            onPressed: _busy
                ? null
                : () async {
                    _revision++;
                    await _closeCamera();
                    if (!context.mounted) return;
                    setState(() {});
                    await showPhotoPrivacy(context);
                    if (mounted && _cameraWanted) await _openCamera();
                  },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_cameraWanted) ...[
              Text(s.photoPosition, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              if (camera != null && camera.value.isInitialized)
                Center(
                  child: SizedBox(
                    width: 300,
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(camera),
                            IgnorePointer(
                              child: Center(
                                child: FractionallySizedBox(
                                  widthFactor: .65,
                                  heightFactor: .75,
                                  child: const CustomPaint(
                                    key: ValueKey('photo-face-guide'),
                                    painter: _FaceGuidePainter(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (!_busy)
                const Icon(Icons.no_photography_outlined, size: 64),
            ] else if (photo != null) ...[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PhotoImage(
                      bytes: photo.bytes,
                      label: s.photoPreview,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(switch (photo.effect) {
                PhotoEffect.nose => s.effectNose,
                PhotoEffect.eyes => s.effectEyes,
                PhotoEffect.wide => s.effectWide,
                PhotoEffect.swirl => s.effectSwirl,
                PhotoEffect.alien => s.effectAlien,
                PhotoEffect.cheeks => s.effectCheeks,
                PhotoEffect.grin => s.effectGrin,
                PhotoEffect.egghead => s.effectEgghead,
                PhotoEffect.squashed => s.effectSquashed,
                PhotoEffect.asymmetric => s.effectAsymmetric,
                PhotoEffect.mini => s.effectMini,
                PhotoEffect.mirror => s.effectMirror,
                PhotoEffect.jelly => s.effectJelly,
                PhotoEffect.fisheye => s.effectFisheye,
              }, textAlign: TextAlign.center),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              Semantics(
                label: s.photoWorking,
                liveRegion: true,
                child: const LinearProgressIndicator(),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(switch (_error) {
                    'permission' => s.photoPermission,
                    'noCamera' => s.photoNoCamera,
                    'noFace' => s.photoNoFace,
                    'manyFaces' => s.photoManyFaces,
                    'landmarks' => s.photoLandmarks,
                    'capture' => s.photoCaptureFailed,
                    'decode' => s.photoDecodeFailed,
                    'detection' => s.photoDetectionFailed,
                    'effect' => s.photoEffectFailed,
                    _ => s.photoFailed,
                  }),
                ),
              ),
            const SizedBox(height: 16),
            if (_cameraWanted) ...[
              FilledButton.icon(
                onPressed: _busy || camera == null ? null : _capture,
                icon: const Icon(Icons.camera_alt),
                label: Text(s.takePhoto),
              ),
              if (!_busy && camera == null)
                OutlinedButton(
                  onPressed: _openCamera,
                  child: Text(s.photoRetry),
                ),
            ] else if (photo != null) ...[
              FilledButton.icon(
                onPressed: _busy || !_active
                    ? null
                    : () => Navigator.pop(context, photo),
                icon: const Icon(Icons.check),
                label: Text(s.usePhoto),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _reroll,
                icon: const Icon(Icons.casino_outlined, size: 32),
                label: Text(s.rollEffect),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () {
                        _cameraWanted = true;
                        unawaited(_openCamera());
                      },
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(s.retakePhoto),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancelPhoto),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  const _FaceGuidePainter();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawOval(
    (Offset.zero & size).deflate(2),
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4,
  );

  @override
  bool shouldRepaint(_FaceGuidePainter oldDelegate) => false;
}
