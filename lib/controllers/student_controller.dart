import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/core/services/attendance_service.dart';
import 'package:bits_mobile_app/core/services/face_registration_service.dart';
import 'package:bits_mobile_app/core/services/mobile_notification_service.dart';
import 'package:bits_mobile_app/core/services/secure_storage_service.dart';
import 'package:bits_mobile_app/core/utils/event_timeline.dart';
import 'package:bits_mobile_app/models/attendance_result_model.dart';
import 'package:bits_mobile_app/models/attended_event_model.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class StudentController extends ChangeNotifier {
  StudentController(this._api, this._notificationService, this._storage);

  final ApiService _api;
  final MobileNotificationService _notificationService;
  final SecureStorageService _storage;
  bool loading = false;
  String? error;
  Map<String, dynamic>? dashboard;
  Map<String, dynamic>? profile;
  bool profileComplete = false;
  int profileCompletion = 0;
  List<String> profileMissingFields = [];
  String? qrCode;
  bool? faceRegistered;
  bool backendFaceRegistered = false;
  bool deviceFaceRegistered = false;
  bool newDeviceDetected = false;
  String? faceStatusMessage;
  bool qrEnabled = true;
  String qrDisabledMessage =
      'QR attendance is currently disabled by the administrator.';
  List<EventModel> events = [];
  List<AttendedEventModel> attendedEvents = [];
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> penalties = [];
  int unreadNotifications = 0;
  DateTime? _eventServerTime;
  DateTime? _eventServerTimeReceivedAt;

  List<Map<String, dynamic>> get announcements => notifications
      .where((item) => item['type']?.toString() == 'announcement')
      .toList();

  Future<void> loadDashboard() async => _load(() async {
    final response = await _api.get(
      '/mobile/student/dashboard',
      cacheDuration: const Duration(minutes: 2),
    );
    dashboard = Map<String, dynamic>.from(response['data'] as Map);
    final profilePayload = Map<String, dynamic>.from(
      dashboard?['profile'] as Map? ?? {},
    );
    _applyProfile(profilePayload);
    final user = Map<String, dynamic>.from(
      profilePayload['user'] as Map? ?? {},
    );
    qrCode = user['qr_code']?.toString();
    final policy = Map<String, dynamic>.from(
      dashboard?['attendance_policy'] as Map? ?? {},
    );
    qrEnabled = _boolValue(policy['qr_enabled'], fallback: true);
    qrDisabledMessage =
        policy['qr_disabled_message']?.toString() ?? qrDisabledMessage;
    await _loadEventList();
  });

  Future<void> loadProfile() async => _load(() async {
    final response = await _api.get(
      '/mobile/student/profile',
      cacheDuration: const Duration(minutes: 15),
    );
    _applyProfile(Map<String, dynamic>.from(response['data'] as Map));
    final user = Map<String, dynamic>.from(profile?['user'] as Map? ?? {});
    qrCode = user['qr_code']?.toString();
  });

  Future<void> loadEvents() async => _load(() async {
    await _loadEventList();

    final attendedResponse = await _api.get(
      '/mobile/student/attendance-history',
      cacheDuration: const Duration(minutes: 1),
    );
    final attendedData = Map<String, dynamic>.from(
      attendedResponse['data'] as Map,
    );
    attendedEvents = (attendedData['attended_events'] as List? ?? [])
        .map(
          (e) =>
              AttendedEventModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  });

  Future<void> _loadEventList() async {
    final eventsResponse = await _api.get(
      '/mobile/student/events',
      cacheDuration: const Duration(minutes: 3),
    );
    final eventsData = Map<String, dynamic>.from(eventsResponse['data'] as Map);
    final serverTime = _parseCampusDateTime(eventsData['server_time']);
    if (serverTime != null) {
      _eventServerTime = serverTime;
      _eventServerTimeReceivedAt = DateTime.now();
    }
    events = (eventsData['events'] as List? ?? [])
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

  Future<void> loadAttendedEvents() async => _load(() async {
    final response = await _api.get(
      '/mobile/student/attendance-history',
      cacheDuration: const Duration(minutes: 1),
    );
    final data = Map<String, dynamic>.from(response['data'] as Map? ?? {});
    final records =
        data['attended_events'] ??
        data['attendance_history'] ??
        data['events'] ??
        response['attended_events'];
    attendedEvents = (records as List? ?? [])
        .map(
          (e) =>
              AttendedEventModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  });

  Future<String?> changePassword(
    String current,
    String password,
    String confirmation,
  ) async {
    try {
      final response = await _api.post('/mobile/student/change-password', {
        'current_password': current,
        'new_password': password,
        'new_password_confirmation': confirmation,
      });
      return response['message']?.toString();
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/mobile/student/profile', data);
      _applyProfile(Map<String, dynamic>.from(response['data'] as Map));
      notifyListeners();
      return response['message']?.toString();
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> uploadProfilePhoto(XFile image) async {
    try {
      final response = await _api.postForm(
        '/mobile/student/profile/photo',
        FormData.fromMap({
          'photo': await MultipartFile.fromFile(
            image.path,
            filename: 'student-profile.jpg',
          ),
        }),
      );
      _applyProfile(Map<String, dynamic>.from(response['data'] as Map));
      notifyListeners();
      return response['message']?.toString();
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to upload the profile photo. Please try again.';
    }
  }

  Future<String?> registerFace(String descriptor) async {
    try {
      final response = await _api.post('/mobile/student/face-registration', {
        'face_descriptor': descriptor,
      });
      return response['message']?.toString();
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> registerFaceImage({
    required XFile image,
    required int studentId,
    required bool livenessDetected,
  }) async {
    try {
      final service = FaceRegistrationService(_api);
      final deviceId = await _storage.readOrCreateDeviceId();
      final result = await service.registerFaceImage(
        image: image,
        studentId: studentId,
        deviceId: deviceId,
        livenessDetected: livenessDetected,
        deviceInfo: {
          'platform': defaultTargetPlatform.name,
          'source': 'student_face_registration',
        },
      );
      if (result.faceRegistered && result.registrationToken != null) {
        await _storage.saveFaceRegistration(
          studentId: studentId,
          token: result.registrationToken!,
          faceTemplate: 'backend-insightface-registration',
        );
      }
      await loadFaceStatus();
      return result.message;
    } on ApiException catch (e) {
      if (e.data['code'] == faceRegisteredOnAnotherDeviceCode) {
        await _storage.clearFaceRegistration();
        faceRegistered = false;
        backendFaceRegistered = true;
        deviceFaceRegistered = false;
        newDeviceDetected = true;
        faceStatusMessage = e.message.isNotEmpty
            ? e.message
            : faceRegisteredOnAnotherDeviceMessage;
        notifyListeners();
      } else if (e.data['code'] == faceAlreadyRegisteredOnThisDeviceCode) {
        backendFaceRegistered = true;
        deviceFaceRegistered = true;
        newDeviceDetected = false;
        faceStatusMessage = e.message;
        notifyListeners();
      }
      return e.message;
    } catch (e) {
      return 'Unable to register face. Please try again.';
    }
  }

  Future<void> loadQrCode() async => _load(() async {
    final response = await _api.get(
      '/mobile/student/qr-code',
      cacheDuration: const Duration(minutes: 30),
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    qrCode = data['qr_code']?.toString();
  });

  Future<void> loadFaceStatus() async => _load(() async {
    final service = FaceRegistrationService(_api);
    final deviceId = await _storage.readOrCreateDeviceId();
    final token = await _storage.readFaceRegistrationToken();
    final status = await service.checkStatus(
      deviceId: deviceId,
      registrationToken: token,
    );
    if (status.localShouldClear) {
      await _storage.clearFaceRegistration();
    }
    final userId = await _storage.readActiveUserId();
    if (userId != null &&
        status.deviceRegistered &&
        status.registrationToken != null &&
        status.registrationToken!.isNotEmpty) {
      await _storage.saveFaceRegistration(
        studentId: userId,
        token: status.registrationToken!,
        faceTemplate: 'backend-insightface-registration',
      );
    }
    faceRegistered = status.faceRegistered;
    backendFaceRegistered = status.backendRegistered;
    deviceFaceRegistered = status.deviceRegistered;
    newDeviceDetected =
        status.newDeviceDetected ||
        status.code == faceRegisteredOnAnotherDeviceCode;
    faceStatusMessage = newDeviceDetected
        ? (status.message ?? faceRegisteredOnAnotherDeviceMessage)
        : status.message;
  });

  Future<Map<String, dynamic>> loadAttendanceValidationContext() async {
    final response = await _api.get(
      '/mobile/student/attendance/validation-context',
    );
    return Map<String, dynamic>.from(response['data'] as Map? ?? {});
  }

  Future<void> saveAttendanceValidationLog(Map<String, dynamic> payload) async {
    try {
      await _api.post('/mobile/student/attendance/validation-log', payload);
    } on ApiException {
      // Validation logs should never prevent the student's next action.
    }
  }

  Future<AttendanceResultModel> submitFaceAttendance({
    required int eventId,
    required XFile image,
    required double latitude,
    required double longitude,
    required double distance,
    required String staticIpStatus,
    required bool developerOptionsEnabled,
  }) async {
    try {
      final deviceId = await _storage.readOrCreateDeviceId();
      final token = await _storage.readFaceRegistrationToken();

      final result = await AttendanceService(_api).submitStudentFaceAttendance(
        eventId: eventId,
        image: image,
        latitude: latitude,
        longitude: longitude,
        distance: distance,
        deviceId: deviceId,
        registrationToken: token ?? '',
        staticIpStatus: staticIpStatus,
        developerOptionsEnabled: developerOptionsEnabled,
        livenessPassed: true,
      );

      await loadAttendedEvents();
      return result;
    } on ApiException catch (e) {
      if (e.data['local_should_clear'] == true ||
          e.data['code'] == faceRegisteredOnAnotherDeviceCode) {
        await _storage.clearFaceRegistration();
        if (e.data['code'] == faceRegisteredOnAnotherDeviceCode) {
          faceRegistered = false;
          backendFaceRegistered = true;
          deviceFaceRegistered = false;
          newDeviceDetected = true;
          faceStatusMessage = e.message.isNotEmpty
              ? e.message
              : faceRegisteredOnAnotherDeviceMessage;
          notifyListeners();
        } else {
          await loadFaceStatus();
        }
      }

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
    }
  }

  Future<void> loadNotifications({bool showDeviceAlerts = false}) async =>
      _load(() async {
        final response = await _api.get(
          '/mobile/student/notifications',
          cacheDuration: const Duration(minutes: 1),
        );
        final data = Map<String, dynamic>.from(response['data'] as Map);
        notifications = (data['notifications'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        unreadNotifications =
            int.tryParse(data['unread_count']?.toString() ?? '') ??
            notifications.where((item) => item['read'] != true).length;
        if (showDeviceAlerts) {
          await _notificationService.showNewEventNotifications(notifications);
        }
      });

  Future<void> markNotificationRead(String id) async {
    await _api.post('/mobile/student/notifications/$id/read', {});
    await loadNotifications();
  }

  Future<void> markAllNotificationsRead() async {
    await _api.post('/mobile/student/notifications/read-all', {});
    await loadNotifications();
  }

  Future<void> loadPenalties() async => _load(() async {
    final response = await _api.get(
      '/mobile/student/penalties',
      cacheDuration: const Duration(minutes: 2),
    );
    final data = Map<String, dynamic>.from(response['data'] as Map? ?? {});
    penalties = (data['penalties'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  });

  Future<void> _load(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _applyProfile(Map<String, dynamic> payload) {
    profile = payload;
    final completion = Map<String, dynamic>.from(
      payload['profile_completion'] as Map? ?? {},
    );
    profileComplete = completion['complete'] == true;
    profileCompletion =
        int.tryParse(completion['percentage']?.toString() ?? '') ?? 0;
    profileMissingFields = (completion['missing_fields'] as List? ?? [])
        .map((value) => value.toString())
        .toList();
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
