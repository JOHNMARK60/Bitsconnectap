import 'dart:convert';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class LocalFaceTemplateService {
  LocalFaceTemplateService()
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

  final FaceDetector _detector;

  Future<String> templateFromImage(XFile image) async {
    final descriptor = await descriptorFromImage(image);
    return jsonEncode({
      'version': 'mlkit-geometry-v1',
      'descriptor': descriptor,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<double> compareWithStoredTemplate({
    required XFile image,
    required String storedTemplate,
  }) async {
    final current = await descriptorFromImage(image);
    final stored = jsonDecode(storedTemplate) as Map<String, dynamic>;
    final expected = (stored['descriptor'] as List? ?? [])
        .map((value) => double.tryParse(value.toString()) ?? 0)
        .toList();
    if (expected.isEmpty || expected.length != current.length) {
      return 0;
    }

    var sum = 0.0;
    for (var i = 0; i < current.length; i++) {
      final delta = current[i] - expected[i];
      sum += delta * delta;
    }

    final distance = sqrt(sum / current.length);
    return (1 - distance).clamp(0.0, 1.0);
  }

  Future<List<double>> descriptorFromImage(XFile image) async {
    final faces = await _detector.processImage(
      InputImage.fromFilePath(image.path),
    );
    if (faces.length != 1) {
      throw const LocalFaceTemplateException(
        'Capture exactly one face before continuing.',
      );
    }

    final face = faces.single;
    final box = face.boundingBox;
    final width = max(1.0, box.width);
    final height = max(1.0, box.height);
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final mouthLeft = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final mouthRight = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    double nx(Point<int>? point) =>
        point == null ? 0.5 : (point.x - box.left) / width;
    double ny(Point<int>? point) =>
        point == null ? 0.5 : (point.y - box.top) / height;

    return [
      (width / height).clamp(0.0, 2.0) / 2,
      ((face.headEulerAngleY ?? 0) + 45).clamp(0.0, 90.0) / 90,
      ((face.headEulerAngleZ ?? 0) + 45).clamp(0.0, 90.0) / 90,
      face.leftEyeOpenProbability ?? 0.5,
      face.rightEyeOpenProbability ?? 0.5,
      face.smilingProbability ?? 0.5,
      nx(leftEye),
      ny(leftEye),
      nx(rightEye),
      ny(rightEye),
      nx(nose),
      ny(nose),
      nx(mouthLeft),
      ny(mouthLeft),
      nx(mouthRight),
      ny(mouthRight),
      nx(mouthBottom),
      ny(mouthBottom),
    ].map((value) => value.clamp(0.0, 1.0).toDouble()).toList();
  }

  Future<void> close() => _detector.close();
}

class LocalFaceTemplateException implements Exception {
  const LocalFaceTemplateException(this.message);

  final String message;

  @override
  String toString() => message;
}
