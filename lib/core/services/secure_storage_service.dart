import 'dart:math';

import 'package:bits_mobile_app/core/services/device_integrity_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _tokenKey = 'auth_token';
  static const _activeUserIdKey = 'active_user_id';
  static const _darkModeKey = 'dark_mode';
  static const _deviceIdKey = 'face_device_id';
  static const _faceRegistrationTokenKey = 'face_registration_token';
  static const _faceRegistrationStudentKey = 'face_registration_student_id';
  static const _faceTemplateKey = 'face_local_template';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(int userId, String token) async {
    await _storage.write(key: _accountKey(_tokenKey, userId), value: token);
    await _storage.write(key: _activeUserIdKey, value: '$userId');
  }

  Future<String?> readToken() async {
    final userId = await readActiveUserId();
    if (userId != null) {
      final accountToken = await _storage.read(
        key: _accountKey(_tokenKey, userId),
      );
      if (accountToken != null && accountToken.trim().isNotEmpty) {
        return accountToken;
      }
    }

    // Keep existing installations signed in once, then migrate the token
    // after /mobile/user identifies its owner.
    return _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    final userId = await readActiveUserId();
    if (userId != null) {
      await _storage.delete(key: _accountKey(_tokenKey, userId));
    }
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _activeUserIdKey);
  }

  Future<int?> readActiveUserId() async {
    final value = await _storage.read(key: _activeUserIdKey);
    return int.tryParse(value ?? '');
  }

  Future<void> saveDarkMode(bool enabled) =>
      _storage.write(key: _darkModeKey, value: enabled ? 'true' : 'false');

  Future<bool> readDarkMode() async =>
      await _storage.read(key: _darkModeKey) == 'true';

  Future<String> readOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final stableAndroidId = await DeviceIntegrityService().readStableDeviceId();
    if (stableAndroidId != null) {
      await _storage.write(key: _deviceIdKey, value: stableAndroidId);
      return stableAndroidId;
    }

    final random = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final deviceId = 'bits-${DateTime.now().millisecondsSinceEpoch}-$random';
    await _storage.write(key: _deviceIdKey, value: deviceId);

    return deviceId;
  }

  Future<String?> readFaceRegistrationToken() async {
    final userId = await readActiveUserId();
    if (userId == null) return null;
    return _storage.read(key: _accountKey(_faceRegistrationTokenKey, userId));
  }

  Future<int?> readFaceRegistrationStudentId() async {
    final userId = await readActiveUserId();
    if (userId == null) return null;
    final value = await _storage.read(
      key: _accountKey(_faceRegistrationStudentKey, userId),
    );
    return int.tryParse(value ?? '');
  }

  Future<void> saveFaceRegistration({
    required int studentId,
    required String token,
    required String faceTemplate,
  }) async {
    await _storage.write(
      key: _accountKey(_faceRegistrationStudentKey, studentId),
      value: '$studentId',
    );
    await _storage.write(
      key: _accountKey(_faceRegistrationTokenKey, studentId),
      value: token,
    );
    await _storage.write(
      key: _accountKey(_faceTemplateKey, studentId),
      value: faceTemplate,
    );
  }

  Future<String?> readFaceTemplate() async {
    final userId = await readActiveUserId();
    if (userId == null) return null;
    return _storage.read(key: _accountKey(_faceTemplateKey, userId));
  }

  Future<void> clearFaceRegistration() async {
    final userId = await readActiveUserId();
    if (userId == null) return;
    await _storage.delete(key: _accountKey(_faceRegistrationTokenKey, userId));
    await _storage.delete(
      key: _accountKey(_faceRegistrationStudentKey, userId),
    );
    await _storage.delete(key: _accountKey(_faceTemplateKey, userId));
  }

  Future<void> migrateLegacyToken(int userId, String token) async {
    await _storage.write(key: _accountKey(_tokenKey, userId), value: token);
    await _storage.delete(key: _tokenKey);
    await _storage.write(key: _activeUserIdKey, value: '$userId');
  }

  Future<void> migrateLegacyFaceRegistration(int userId) async {
    final legacyStudentId = int.tryParse(
      await _storage.read(key: _faceRegistrationStudentKey) ?? '',
    );
    if (legacyStudentId != userId) return;

    final legacyToken = await _storage.read(key: _faceRegistrationTokenKey);
    final legacyTemplate = await _storage.read(key: _faceTemplateKey);
    if (legacyToken != null && legacyToken.trim().isNotEmpty) {
      await _storage.write(
        key: _accountKey(_faceRegistrationTokenKey, userId),
        value: legacyToken,
      );
    }
    if (legacyTemplate != null && legacyTemplate.trim().isNotEmpty) {
      await _storage.write(
        key: _accountKey(_faceTemplateKey, userId),
        value: legacyTemplate,
      );
    }
    await _storage.write(
      key: _accountKey(_faceRegistrationStudentKey, userId),
      value: '$userId',
    );
    await _storage.delete(key: _faceRegistrationTokenKey);
    await _storage.delete(key: _faceRegistrationStudentKey);
    await _storage.delete(key: _faceTemplateKey);
  }

  String _accountKey(String base, int userId) => '${base}_$userId';
}
