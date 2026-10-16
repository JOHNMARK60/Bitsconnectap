import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/core/services/attendance_service.dart';
import 'package:bits_mobile_app/core/services/location_service.dart';
import 'package:bits_mobile_app/core/utils/event_timeline.dart';
import 'package:bits_mobile_app/core/utils/geofence_helper.dart';
import 'package:bits_mobile_app/models/attendance_result_model.dart';
import 'package:bits_mobile_app/models/attended_event_model.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/models/scan_result_model.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class ScannerController extends ChangeNotifier {
  ScannerController(this._api, this._locationService);

  final ApiService _api;
  final LocationService _locationService;
  bool loading = false;
  String? error;
  Map<String, dynamic>? dashboard;
  List<EventModel> events = [];
  List<Map<String, dynamic>> students = [];
  List<AttendedEventModel> history = [];
  Map<String, dynamic>? verifiedStudent;
  bool qrEnabled = true;
  bool scannerEnabled = true;
  String qrDisabledMessage =
      'QR attendance is currently disabled by the administrator.';
  String scannerDisabledMessage =
      'Scanner attendance is currently disabled by the administrator.';
  DateTime? _eventServerTime;
  DateTime? _eventServerTimeReceivedAt;
  bool _attendanceSubmissionInProgress = false;

  static const String _submissionInProgressMessage =
      'An attendance request is already being processed. Please wait.';

  Future<void> loadDashboard() async => _load(() async {
    final response = await _api.get(
      '/mobile/scanner/dashboard',
      cacheDuration: const Duration(seconds: 30),
    );
    dashboard = Map<String, dynamic>.from(response['data'] as Map);
    final policy = Map<String, dynamic>.from(
      dashboard?['attendance_policy'] as Map? ?? {},
    );
    qrEnabled = _boolValue(policy['qr_enabled'], fallback: true);
    scannerEnabled = _boolValue(policy['scanner_enabled'], fallback: true);
    qrDisabledMessage =
        policy['qr_disabled_message']?.toString() ?? qrDisabledMessage;
    scannerDisabledMessage =
        policy['scanner_disabled_message']?.toString() ??
        scannerDisabledMessage;
    await _loadEventList();
  });

  Future<void> loadEvents() async => _load(() async {
    await _loadEventList();
  });

  Future<void> _loadEventList() async {
    final response = await _api.get(
      '/mobile/scanner/events',
      cacheDuration: const Duration(seconds: 30),
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final serverTime = _parseCampusDateTime(data['server_time']);
    if (serverTime != null) {
      _eventServerTime = serverTime;
      _eventServerTimeReceivedAt = DateTime.now();
    }
    events = (data['events'] as List)
        .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  DateTime eventReferenceTime() {
    final serverTime = _eventServerTime;
    final receivedAt = _eventServerTimeReceivedAt;
    if (serverTime == null || receivedAt == null) {
      return EventTimeline.campusNow();
    }

    return serverTime.add(DateTime.now().difference(receivedAt));
  }

  Future<void> loadHistory() async => _load(() async {
    final response = await _api.get(
      '/mobile/scanner/scan-history',
      cacheDuration: const Duration(seconds: 30),
    );
    final data = Map<String, dynamic>.from(response['data'] as Map? ?? {});
    final records =
        data['scan_history'] ??
        data['history'] ??
        data['attendance_logs'] ??
        response['scan_history'];
    history = (records as List? ?? [])
        .map(
          (e) =>
              AttendedEventModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList()
      ..sort((a, b) {
        final aTime = a.loginTime ?? a.scannedTime;
        final bTime = b.loginTime ?? b.scannedTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });
  });

  Future<void> loadStudents() async => _load(() async {
    final response = await _api.get('/mobile/scanner/students');
    final data = Map<String, dynamic>.from(response['data'] as Map? ?? {});
    students = (data['students'] as List? ?? [])
        .map((student) => Map<String, dynamic>.from(student as Map))
        .toList();
  });

  Future<String> registerStudentFace(int studentId, XFile image) async {
    try {
      final response = await _api.postForm(
        '/mobile/scanner/students/$studentId/face/register',
        FormData.fromMap({
          'image': await MultipartFile.fromFile(
            image.path,
            filename: 'student-face.jpg',
          ),
          'liveness_passed': '1',
          'liveness_detected': '1',
          'liveness_method': 'blink',
        }),
      );
      await loadStudents();
      return response['message']?.toString() ??
          'Student face registered successfully.';
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'Unable to register the student face. Please try again.';
    }
  }

  Future<ScanResultModel> scan(
    String qrCode,
    int eventId, {
    String? qrFallbackReason,
    String? qrFallbackOtherReason,
  }) async {
    if (_attendanceSubmissionInProgress) {
      return const ScanResultModel(
        message: _submissionInProgressMessage,
        status: 'error',
      );
    }

    _attendanceSubmissionInProgress = true;
    try {
      final event = eventById(eventId);
      final disabledMessage = qrPolicyMessage(event);
      if (disabledMessage != null) {
        return ScanResultModel(message: disabledMessage, status: 'error');
      }

      // Flutter performs an early check for quick feedback. Laravel repeats
      // this calculation and remains the authority before attendance is saved.
      debugPrint('Retrieving GPS location for attendance validation.');
      final Position position = await _locationService.getCurrentLocation();
      debugPrint(
        'Location retrieved: lat=${position.latitude}, '
        'longitude=${position.longitude}.',
      );

      final double distance = GeofenceHelper.calculateDistanceToVenue(
        position.latitude,
        position.longitude,
        event?.attendanceVenue,
      );
      final radius = GeofenceHelper.allowedRadiusForVenue(
        event?.attendanceVenue,
      );
      debugPrint(
        'Calculated event distance: ${distance.toStringAsFixed(2)} meters.',
      );

      if (distance > radius) {
        debugPrint(
          'Student outside ${radius.toStringAsFixed(0)}-meter radius: '
          '${distance.toStringAsFixed(2)} meters away.',
        );
        return const ScanResultModel(
          message: GeofenceHelper.outsideRadiusMessage,
          status: 'error',
        );
      }

      debugPrint(
        'Student inside ${radius.toStringAsFixed(0)}-meter radius: '
        '${distance.toStringAsFixed(2)} meters away.',
      );

      // The submitted distance is informational. Laravel recalculates it from
      // latitude/longitude and saves only its own authoritative result.
      final payload = <String, dynamic>{
        'event_id': eventId,
        'qr_code': qrCode,
        'confirmed_present': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'distance': distance,
      };
      if (qrFallbackReason != null) {
        payload['qr_fallback_reason'] = qrFallbackReason;
      }
      if (qrFallbackOtherReason != null) {
        payload['qr_fallback_other_reason'] = qrFallbackOtherReason;
      }

      final response = await _api.post('/mobile/scanner/scan', payload);

      debugPrint('Successful attendance validation by Laravel.');
      await loadHistory();
      return ScanResultModel.fromResponse(response);
    } on LocationServiceException catch (error) {
      debugPrint('Attendance location validation failed: ${error.message}');
      return ScanResultModel(message: error.message, status: 'error');
    } on ApiException catch (e) {
      return ScanResultModel(message: e.message, status: 'error');
    } catch (error) {
      debugPrint('Unexpected attendance location failure: $error');
      return const ScanResultModel(
        message: 'Unable to validate your location. Please try again.',
        status: 'error',
      );
    } finally {
      _attendanceSubmissionInProgress = false;
    }
  }

  Future<Map<String, dynamic>?> verifyQr(String qrCode, {int? eventId}) async {
    try {
      final disabledMessage = qrPolicyMessage(eventById(eventId));
      if (disabledMessage != null) {
        error = disabledMessage;
        notifyListeners();
        return null;
      }

      final payload = <String, dynamic>{'qr_code': qrCode};
      if (eventId != null) {
        payload['event_id'] = eventId;
      }

      final response = await _api.post('/mobile/scanner/qr/verify', payload);
      verifiedStudent = Map<String, dynamic>.from(response['data'] as Map);
      notifyListeners();
      return verifiedStudent;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      error = 'Unable to verify the QR code. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<String> voidQr({
    required String qrCode,
    required int eventId,
    required String voidReason,
    String? voidNotes,
  }) async {
    if (_attendanceSubmissionInProgress) {
      return _submissionInProgressMessage;
    }

    _attendanceSubmissionInProgress = true;
    try {
      final response = await _api.post('/mobile/scanner/qr/void', {
        'qr_code': qrCode,
        'event_id': eventId,
        'void_reason': voidReason,
        if (voidNotes != null && voidNotes.trim().isNotEmpty)
          'void_notes': voidNotes,
      });
      await loadHistory();
      return response['message']?.toString() ?? 'QR attendance voided.';
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to void attendance. Please try again.';
    } finally {
      _attendanceSubmissionInProgress = false;
    }
  }

  Future<Map<String, dynamic>> faceVerify(XFile image) async {
    try {
      final response = await _api.postForm(
        '/mobile/scanner/face-verify',
        FormData.fromMap({
          'face_image': await MultipartFile.fromFile(
            image.path,
            filename: 'face-verify.jpg',
          ),
        }),
      );
      return Map<String, dynamic>.from(response['data'] as Map);
    } on ApiException catch (e) {
      return {
        ...e.data,
        'verified': false,
        'reason': e.message,
        'message': e.message,
      };
    }
  }

  Future<AttendanceResultModel> scanFaceAttendance({
    required int eventId,
    required XFile image,
  }) async {
    if (_attendanceSubmissionInProgress) {
      return const AttendanceResultModel(
        success: false,
        message: _submissionInProgressMessage,
      );
    }

    _attendanceSubmissionInProgress = true;
    try {
      final disabledMessage = scannerPolicyMessage(eventById(eventId));
      if (disabledMessage != null) {
        return AttendanceResultModel(success: false, message: disabledMessage);
      }

      final position = await _locationService.getCurrentLocation();
      final event = eventById(eventId);
      final distance = GeofenceHelper.calculateDistanceToVenue(
        position.latitude,
        position.longitude,
        event?.attendanceVenue,
      );
      if (distance >
          GeofenceHelper.allowedRadiusForVenue(event?.attendanceVenue)) {
        return const AttendanceResultModel(
          success: false,
          message: GeofenceHelper.outsideRadiusMessage,
        );
      }

      return AttendanceService(_api).submitFaceAttendance(
        eventId: eventId,
        faceImage: image,
        latitude: position.latitude,
        longitude: position.longitude,
        distance: distance,
      );
    } on LocationServiceException {
      return const AttendanceResultModel(
        success: false,
        message: 'Please allow location access to record attendance.',
      );
    } on ApiException catch (e) {
      return AttendanceResultModel.fromJson({
        ...e.data,
        'success': false,
        'message': e.message,
      });
    } catch (_) {
      return const AttendanceResultModel(
        success: false,
        message: 'Unable to process face attendance.',
      );
    } finally {
      _attendanceSubmissionInProgress = false;
    }
  }

  Future<void> _load(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Unable to load scanner data. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  EventModel? eventById(int? eventId) {
    if (eventId == null) return null;
    for (final event in events) {
      if (event.id == eventId) return event;
    }
    return null;
  }

  String? scannerPolicyMessage(EventModel? event) {
    if (!scannerEnabled || event?.scannerEnabled == false) {
      return scannerDisabledMessage;
    }
    if (event != null && !event.isAttendancePhaseOpen) {
      return event.attendancePhaseMessage;
    }
    return null;
  }

  String? qrPolicyMessage(EventModel? event) {
    final scannerMessage = scannerPolicyMessage(event);
    if (scannerMessage != null) return scannerMessage;
    if (!qrEnabled || event?.qrEnabled == false) {
      return qrDisabledMessage;
    }
    return null;
  }
}

bool _boolValue(Object? value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final text = value.toString().trim().toLowerCase();
  if (text == '1' || text == 'true' || text == 'yes' || text == 'on') {
    return true;
  }
  if (text == '0' || text == 'false' || text == 'no' || text == 'off') {
    return false;
  }
  return fallback;
}

DateTime? _parseCampusDateTime(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;

  if (parsed.isUtc || RegExp(r'(Z|[+-]\d\d:?\d\d)$').hasMatch(text)) {
    final campusClock = parsed.toUtc().add(const Duration(hours: 8));

    return DateTime(
      campusClock.year,
      campusClock.month,
      campusClock.day,
      campusClock.hour,
      campusClock.minute,
      campusClock.second,
      campusClock.millisecond,
      campusClock.microsecond,
    );
  }

  return parsed;
}
