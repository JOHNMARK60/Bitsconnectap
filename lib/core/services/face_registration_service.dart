import 'dart:convert';

import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';

const faceRegisteredOnAnotherDeviceCode = 'FACE_REGISTERED_ON_ANOTHER_DEVICE';
const faceRegisteredOnAnotherDeviceMessage =
    'New device detected. Your face is already registered on another device. Please contact the administrator to reset your face registration.';
const faceAlreadyRegisteredOnThisDeviceCode =
    'FACE_ALREADY_REGISTERED_ON_THIS_DEVICE';

class FaceRegistrationService {
  FaceRegistrationService(this._api);

  final ApiService _api;

  Future<FaceRegistrationResult> registerFaceImage({
    required XFile image,
    required int studentId,
    required String deviceId,
    required bool livenessDetected,
    Map<String, dynamic> deviceInfo = const {},
    Map<String, dynamic> metadata = const {},
  }) async {
    final registeredAt = DateTime.now().toIso8601String();
    final response = await _api.postForm(
      '/mobile/student/face/register',
      FormData.fromMap({
        'student_id': studentId,
        'device_id': deviceId,
        'registered_at': registeredAt,
        'model_version': 'insightface-backend-v1',
        'liveness_method': 'blink',
        'liveness_passed': livenessDetected ? '1' : '0',
        'liveness_detected': livenessDetected ? '1' : '0',
        'device_info': jsonEncode(deviceInfo),
        'metadata': jsonEncode({
          ...metadata,
          'registered_at': registeredAt,
          'source': 'student_face_registration',
        }),
        'image': await MultipartFile.fromFile(
          image.path,
          filename: 'face-registration.jpg',
        ),
      }),
    );

    return FaceRegistrationResult.fromJson(response);
  }

  Future<FaceStatusResult> checkStatus({
    required String deviceId,
    String? registrationToken,
  }) async {
    final query = Uri(
      queryParameters: {
        'device_id': deviceId,
        if (registrationToken != null && registrationToken.isNotEmpty)
          'registration_token': registrationToken,
      },
    ).query;
    final response = await _api.get('/mobile/student/face/status?$query');

    return FaceStatusResult.fromJson(response);
  }
}

class FaceRegistrationResult {
  const FaceRegistrationResult({
    required this.message,
    required this.faceRegistered,
    this.registrationToken,
    this.deviceId,
    this.code,
  });

  final String message;
  final bool faceRegistered;
  final String? registrationToken;
  final String? deviceId;
  final String? code;

  factory FaceRegistrationResult.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});

    return FaceRegistrationResult(
      message: json['message']?.toString() ?? 'Face registered successfully.',
      faceRegistered: data['face_registered'] == true,
      registrationToken: data['registration_token']?.toString(),
      deviceId: data['device_id']?.toString(),
      code: data['code']?.toString() ?? json['code']?.toString(),
    );
  }
}

class FaceStatusResult {
  const FaceStatusResult({
    required this.faceRegistered,
    required this.backendRegistered,
    required this.deviceRegistered,
    required this.localShouldClear,
    required this.newDeviceDetected,
    this.registrationToken,
    this.message,
    this.code,
  });

  final bool faceRegistered;
  final bool backendRegistered;
  final bool deviceRegistered;
  final bool localShouldClear;
  final bool newDeviceDetected;
  final String? registrationToken;
  final String? message;
  final String? code;

  factory FaceStatusResult.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});

    return FaceStatusResult(
      faceRegistered: data['face_registered'] == true,
      backendRegistered: data['backend_registered'] == true,
      deviceRegistered: data['device_registered'] == true,
      localShouldClear: data['local_should_clear'] == true,
      newDeviceDetected: data['new_device_detected'] == true,
      registrationToken: data['registration_token']?.toString(),
      message: data['message']?.toString() ?? json['message']?.toString(),
      code: data['code']?.toString() ?? json['code']?.toString(),
    );
  }
}
