import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ApiCacheService {
  static const _prefix = 'api_cache_v1_';

  Future<Map<String, dynamic>?> read(
    String key, {
    required Duration maxAge,
    bool allowExpired = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('$_prefix$key');
    if (raw == null) return null;

    try {
      final envelope = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        envelope['saved_at'] as int,
      );
      if (!allowExpired && DateTime.now().difference(savedAt) > maxAge) {
        return null;
      }
      return Map<String, dynamic>.from(envelope['data'] as Map);
    } catch (_) {
      await preferences.remove('$_prefix$key');
      return null;
    }
  }

  Future<void> write(String key, Map<String, dynamic> data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_prefix$key',
      jsonEncode({
        'saved_at': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<void> clearForUser(int? userId) async {
    if (userId == null) return;
    final preferences = await SharedPreferences.getInstance();
    final userPrefix = '${_prefix}user_${userId}_';
    await Future.wait(
      preferences
          .getKeys()
          .where((key) => key.startsWith(userPrefix))
          .map(preferences.remove),
    );
  }
}
