import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceLivenessCapture {
  const FaceLivenessCapture._();

  static Future<XFile?> capture(
    BuildContext context, {
    String title = 'Face Verification',
  }) async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required.')),
        );
      }
      return null;
    }

    final cameras = await availableCameras();
    if (!context.mounted) return null;
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera was found on this device.')),
      );
      return null;
    }

    final selected = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final camera = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: _cameraImageFormatGroup,
    );

    try {
      await camera.initialize();
      if (!context.mounted) return null;

      return await showDialog<XFile?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _FaceLivenessDialog(camera: camera, title: title),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the camera. Please try again.'),
          ),
        );
      }
      return null;
    } finally {
      await camera.dispose();
    }
  }
}

ImageFormatGroup get _cameraImageFormatGroup {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => ImageFormatGroup.nv21,
    TargetPlatform.iOS => ImageFormatGroup.bgra8888,
    _ => ImageFormatGroup.yuv420,
  };
}

enum _LivenessPhase { align, flash, blink, passed, verifying }

class _FaceLivenessDialog extends StatefulWidget {
  const _FaceLivenessDialog({required this.camera, required this.title});

  final CameraController camera;
  final String title;

  @override
  State<_FaceLivenessDialog> createState() => _FaceLivenessDialogState();
}

class _FaceLivenessDialogState extends State<_FaceLivenessDialog> {
  static const _flashColors = [Color(0xFF0D6EFD), Color(0xFF2563EB)];

  late final FaceDetector _faceDetector;
  Timer? _flashTimer;
  bool _processing = false;
  bool _finishing = false;
  bool _sawOpenEyes = false;
  bool _sawClosedEyes = false;
  int _flashTick = 0;
  _LivenessPhase _phase = _LivenessPhase.align;

  CameraController get camera => widget.camera;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    unawaited(
      camera.startImageStream(_processImage).catchError((_) {
        if (mounted) setState(() => _phase = _LivenessPhase.align);
      }),
    );
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    if (camera.value.isStreamingImages) {
      unawaited(camera.stopImageStream());
    }
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = switch (_phase) {
      _LivenessPhase.flash => _flashColors[_flashTick % _flashColors.length],
      _LivenessPhase.passed => const Color(0xFFDCFCE7),
      _ => Colors.white,
    };
    final progress = _phase == _LivenessPhase.flash
        ? (_flashTick / 12).clamp(0.0, 1.0)
        : _phase == _LivenessPhase.blink || _phase == _LivenessPhase.verifying
        ? 1.0
        : 0.0;
    final instruction = switch (_phase) {
      _LivenessPhase.align => 'Please put your face into the frame',
      _LivenessPhase.flash =>
        'Please keep steady while the light is flashing ...',
      _LivenessPhase.blink => 'Please blink your eyes',
      _LivenessPhase.passed => 'Liveness passed. Hold still',
      _LivenessPhase.verifying => 'Verifying your face ...',
    };
    final status = switch (_phase) {
      _LivenessPhase.align => 'Step 1 of 3 · Align your face',
      _LivenessPhase.flash => 'Step 2 of 3 · Hold still',
      _LivenessPhase.blink => 'Step 2 of 3 · Blink once',
      _LivenessPhase.passed => 'Step 3 of 3 · Liveness passed',
      _LivenessPhase.verifying => 'Step 3 of 3 · Checking face',
    };

    return Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(title: widget.title),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: double.infinity,
                    color: background,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final diameter = math
                            .min(constraints.maxWidth * .66, 230.0)
                            .clamp(190.0, 230.0);
                        final topGap = _phase == _LivenessPhase.align
                            ? 72.0
                            : 52.0;

                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: topGap),
                                _CircularFacePreview(
                                  camera: camera,
                                  diameter: diameter,
                                  progress: progress,
                                  showProgress: _phase != _LivenessPhase.align,
                                  progressColor: _phase == _LivenessPhase.passed
                                      ? const Color(0xFF16A34A)
                                      : Colors.white,
                                ),
                                const SizedBox(height: 42),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 34,
                                  ),
                                  child: Text(
                                    instruction,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      height: 1.18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: _phase == _LivenessPhase.passed
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFF475569),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (_phase == _LivenessPhase.blink) ...[
                                  const SizedBox(height: 32),
                                  const _BlinkAvatar(),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_phase == _LivenessPhase.verifying) const _VerifyingOverlay(),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage(CameraImage image) async {
    if (_processing || _finishing) return;
    _processing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted || _finishing) return;

      final aligned = faces.length == 1 && _isAligned(faces.first, image);
      if (!aligned) {
        if (_phase != _LivenessPhase.align) _resetToAlignment();
        return;
      }

      if (_phase == _LivenessPhase.align) {
        _beginFlashing();
        return;
      }

      if (_phase == _LivenessPhase.blink) {
        _handleBlink(faces.first);
      }
    } catch (_) {
      if (mounted && _phase != _LivenessPhase.align) {
        _resetToAlignment();
      }
    } finally {
      _processing = false;
    }
  }

  void _beginFlashing() {
    if (_phase == _LivenessPhase.flash) return;
    setState(() {
      _phase = _LivenessPhase.flash;
      _flashTick = 0;
      _sawOpenEyes = false;
      _sawClosedEyes = false;
    });

    _flashTimer?.cancel();
    _flashTimer = Timer.periodic(const Duration(milliseconds: 280), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_flashTick >= 12) {
        timer.cancel();
        setState(() => _phase = _LivenessPhase.blink);
        return;
      }
      setState(() => _flashTick += 1);
    });
  }

  void _resetToAlignment() {
    _flashTimer?.cancel();
    setState(() {
      _phase = _LivenessPhase.align;
      _flashTick = 0;
      _sawOpenEyes = false;
      _sawClosedEyes = false;
    });
  }

  void _handleBlink(Face face) {
    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    if (left == null || right == null) return;

    final eyesOpen = left > .72 && right > .72;
    final eyesClosed = left < .38 && right < .38;
    if (eyesOpen && !_sawClosedEyes) {
      _sawOpenEyes = true;
    } else if (_sawOpenEyes && eyesClosed) {
      _sawClosedEyes = true;
    } else if (_sawOpenEyes && _sawClosedEyes && eyesOpen) {
      setState(() => _phase = _LivenessPhase.passed);
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 450), _finishCapture),
      );
    }
  }

  Future<void> _finishCapture() async {
    if (_finishing) return;
    _finishing = true;
    _flashTimer?.cancel();
    setState(() => _phase = _LivenessPhase.verifying);

    try {
      if (camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }
      await Future<void>.delayed(const Duration(milliseconds: 650));
      final image = await camera.takePicture();
      if (mounted) Navigator.pop(context, image);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  bool _isAligned(Face face, CameraImage image) {
    final box = face.boundingBox;
    final rawSize = Size(image.width.toDouble(), image.height.toDouble());
    final sensorOrientation = camera.description.sensorOrientation;
    final rotatedSize = sensorOrientation == 90 || sensorOrientation == 270
        ? Size(rawSize.height, rawSize.width)
        : rawSize;

    return _boxLooksUsable(box, rawSize) || _boxLooksUsable(box, rotatedSize);
  }

  bool _boxLooksUsable(Rect box, Size size) {
    final minSide = math.min(size.width, size.height);
    final center = box.center;

    return box.width >= minSide * .12 &&
        box.height >= minSide * .12 &&
        center.dx > size.width * .02 &&
        center.dx < size.width * .98 &&
        center.dy > size.height * .02 &&
        center.dy < size.height * .98;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final rotation =
        InputImageRotationValue.fromRawValue(
          camera.description.sensorOrientation,
        ) ??
        InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

    final bytes = WriteBuffer();
    if (image.planes.length == 1) {
      bytes.putUint8List(image.planes.first.bytes);
    } else {
      for (final plane in image.planes) {
        bytes.putUint8List(plane.bytes);
      }
    }

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              tooltip: 'Back',
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _CircularFacePreview extends StatelessWidget {
  const _CircularFacePreview({
    required this.camera,
    required this.diameter,
    required this.progress,
    required this.showProgress,
    required this.progressColor,
  });

  final CameraController camera;
  final double diameter;
  final double progress;
  final bool showProgress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter + 18,
      height: diameter + 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(diameter + 16),
            painter: _ProgressRingPainter(
              progress: progress,
              showProgress: showProgress,
              color: progressColor,
            ),
          ),
          ClipOval(
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: _CoverCameraPreview(camera: camera),
            ),
          ),
          SizedBox(
            width: diameter,
            height: diameter,
            child: CustomPaint(painter: _FaceOutlinePainter()),
          ),
        ],
      ),
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.camera});

  final CameraController camera;

  @override
  Widget build(BuildContext context) {
    final value = camera.value;
    if (!value.isInitialized) return const ColoredBox(color: Colors.black);

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: value.previewSize?.height ?? 1,
        height: value.previewSize?.width ?? 1,
        child: CameraPreview(camera),
      ),
    );
  }
}

class _FaceOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * .35, size.height * .80)
      ..cubicTo(
        size.width * .25,
        size.height * .72,
        size.width * .24,
        size.height * .61,
        size.width * .27,
        size.height * .51,
      )
      ..cubicTo(
        size.width * .20,
        size.height * .48,
        size.width * .21,
        size.height * .36,
        size.width * .29,
        size.height * .38,
      )
      ..cubicTo(
        size.width * .31,
        size.height * .17,
        size.width * .43,
        size.height * .08,
        size.width * .50,
        size.height * .08,
      )
      ..cubicTo(
        size.width * .57,
        size.height * .08,
        size.width * .69,
        size.height * .17,
        size.width * .71,
        size.height * .38,
      )
      ..cubicTo(
        size.width * .79,
        size.height * .36,
        size.width * .80,
        size.height * .48,
        size.width * .73,
        size.height * .51,
      )
      ..cubicTo(
        size.width * .76,
        size.height * .61,
        size.width * .75,
        size.height * .72,
        size.width * .65,
        size.height * .80,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.showProgress,
    required this.color,
  });

  final double progress;
  final bool showProgress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = rect.deflate(4);
    final base = Paint()
      ..color = const Color(0xFFE8E8EE)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    final active = Paint()
      ..color = color
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    canvas.drawOval(circle, base);
    if (showProgress) {
      canvas.drawArc(
        circle,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        active,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showProgress != showProgress ||
        oldDelegate.color != color;
  }
}

class _BlinkAvatar extends StatelessWidget {
  const _BlinkAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F1F6),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.face_retouching_natural,
        color: Color(0xFF111827),
        size: 58,
      ),
    );
  }
}

class _VerifyingOverlay extends StatelessWidget {
  const _VerifyingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCC071426),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .88, end: 1),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 306,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEAF2FF),
                      border: Border.all(
                        color: const Color(0xFFBFD8FF),
                        width: 5,
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        color: Color(0xFF0D6EFD),
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Securing your attendance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Matching your live face with your registered profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _VerificationStep(
                    icon: Icons.check_circle,
                    text: 'Liveness confirmed',
                    complete: true,
                  ),
                  const _VerificationStep(
                    icon: Icons.face_retouching_natural,
                    text: 'Comparing face profile',
                    complete: false,
                  ),
                  const _VerificationStep(
                    icon: Icons.cloud_done_outlined,
                    text: 'Saving attendance securely',
                    complete: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.icon,
    required this.text,
    required this.complete,
  });

  final IconData icon;
  final String text;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: complete ? const Color(0xFF16A34A) : const Color(0xFF0D6EFD),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: complete
                  ? const Color(0xFF166534)
                  : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
