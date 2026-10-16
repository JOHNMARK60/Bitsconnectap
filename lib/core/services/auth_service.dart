import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/core/services/secure_storage_service.dart';
import 'package:bits_mobile_app/models/user_model.dart';

class AuthService {
  AuthService(this._api, this._storage);

  final ApiService _api;
  final SecureStorageService _storage;

  Future<UserModel> login(String email, String password) async {
    final response = await _api.post('/mobile/login', {
      'email': email,
      'password': password,
      'device_name': 'BITSConnect',
    });
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final user = UserModel.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    await _storage.saveToken(user.id, data['token'].toString());
    await _storage.migrateLegacyFaceRegistration(user.id);
    return user;
  }

  Future<UserModel?> restoreUser() async {
    final token = await _storage.readToken();
    if (token == null) return null;

    try {
      final response = await _api.get('/mobile/user');
      final data = Map<String, dynamic>.from(response['data'] as Map);
      final user = UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
      await _storage.migrateLegacyToken(user.id, token);
      await _storage.migrateLegacyFaceRegistration(user.id);
      return user;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 419) {
        await _storage.clearToken();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/mobile/logout', {});
    } finally {
      await _storage.clearToken();
    }
  }
}
