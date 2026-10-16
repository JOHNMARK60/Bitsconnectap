import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/models/attendance_result_model.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';

class AttendanceService {
  AttendanceService(this._api);

  final ApiService _api;

  Future<AttendanceResultModel> submitFaceAttendance({
    required int eventId,
    required XFile faceImage,
    required double latitude,
    required double longitude,
    required double distance,
    bool livenessPassed = true,
  }) async {
    // Laravel endpoint expected by the scanner face-attendance module:
    // POST /api/mobile/scanner/attendance/face
    // multipart/form-data:
    // - event_id
    // - face_image: image file
    // - scanned_at
    //
    // Laravel must send this image to Python AI for embedding generation and
    // comparison. Flutter only displays recognition when Laravel returns it.
    final response = await _api.postForm(
      '/mobile/scanner/attendance/face',
      FormData.fromMap({
        'event_id': eventId,
        'image': await MultipartFile.fromFile(
          faceImage.path,
          filename: 'attendance-face.jpg',
        ),
        'scanned_at': DateTime.now().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'distance': distance,
        'liveness_passed': livenessPassed ? '1' : '0',
        'liveness_detected': livenessPassed ? '1' : '0',
        'liveness_method': 'blink',
      }),
    );

    return AttendanceResultModel.fromJson(response);
  }

  Future<AttendanceResultModel> submitStudentFaceAttendance({
    required int eventId,
    required XFile image,
    required double latitude,
    required double longitude,
    required double distance,
    required String deviceId,
    required String registrationToken,
    required String staticIpStatus,
    required bool developerOptionsEnabled,
    required bool livenessPassed,
  }) async {
    final response = await _api.postForm(
      '/mobile/student/attendance/face',
      FormData.fromMap({
        'event_id': eventId,
        'scanned_at': DateTime.now().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'distance': distance,
        'device_id': deviceId,
        'registration_token': registrationToken,
        'static_ip_status': staticIpStatus,
        'developer_options_enabled': developerOptionsEnabled ? '1' : '0',
        'liveness_passed': livenessPassed ? '1' : '0',
        'liveness_detected': livenessPassed ? '1' : '0',
        'liveness_method': 'blink',
        'image': await MultipartFile.fromFile(
          image.path,
          filename: 'face-attendance.jpg',
        ),
      }),
    );

    return AttendanceResultModel.fromJson(response);
  }
}
