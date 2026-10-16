import 'package:bits_mobile_app/core/constants/api_config.dart';
import 'package:bits_mobile_app/core/services/api_cache_service.dart';
import 'package:bits_mobile_app/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';

class ApiService {
  ApiService(this._storage) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = ApiConfig.baseUrl;
          final token = await _storage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          handler.next(options);
        },
      ),
    );
  }

  final SecureStorageService _storage;
  final ApiCacheService _cache = ApiCacheService();
  final Map<String, Future<Map<String, dynamic>>> _pendingGets = {};
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<Map<String, dynamic>> get(
    String path, {
    Duration? cacheDuration,
    bool forceRefresh = false,
  }) async {
    if (cacheDuration == null) return _getFromServer(path);

    final userId = await _storage.readActiveUserId();
    final cacheKey = _cacheKey(userId, path);
    if (!forceRefresh) {
      final cached = await _cache.read(cacheKey, maxAge: cacheDuration);
      if (cached != null) return cached;
    }

    final pending = _pendingGets[cacheKey];
    if (pending != null) return pending;

    final request = _getAndCache(path, cacheKey, cacheDuration);
    _pendingGets[cacheKey] = request;
    try {
      return await request;
    } finally {
      _pendingGets.remove(cacheKey);
    }
  }

  Future<Map<String, dynamic>> _getAndCache(
    String path,
    String cacheKey,
    Duration cacheDuration,
  ) async {
    try {
      final response = await _getFromServer(path);
      await _cache.write(cacheKey, response);
      return response;
    } on ApiException {
      final stale = await _cache.read(
        cacheKey,
        maxAge: cacheDuration,
        allowExpired: true,
      );
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getFromServer(String path) async {
    try {
      final response = await _dio.get(_relativePath(path));
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(_relativePath(path), data: data);
      await _clearCurrentUserCache();
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(_relativePath(path), data: data);
      await _clearCurrentUserCache();
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> postForm(String path, FormData data) async {
    try {
      // Multipart requests are used by face registration and attendance. Set
      // the bearer token on the request itself as well as in the interceptor;
      // this avoids a race where Dio starts a multipart request before the
      // async request interceptor has finished reading secure storage.
      final token = await _storage.readToken();
      final response = await _dio.post(
        _relativePath(path),
        data: data,
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.trim().isNotEmpty)
              'Authorization': 'Bearer ${token.trim()}',
          },
        ),
      );
      await _clearCurrentUserCache();
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 419) {
        await _storage.clearToken();
      }
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(_relativePath(path));
      await _clearCurrentUserCache();
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  String _relativePath(String path) {
    final normalized = path.replaceFirst(RegExp(r'^/+'), '');

    // Keep callers that still pass `/mobile/...` compatible while the API
    // base remains explicitly pinned to `/api/mobile/` (never `/api/v1/`).
    return normalized.replaceFirst(RegExp(r'^mobile/+'), '');
  }

  String _cacheKey(int? userId, String path) {
    final normalized = _relativePath(
      path,
    ).replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    return 'user_${userId ?? 0}_$normalized';
  }

  Future<void> _clearCurrentUserCache() async {
    await _cache.clearForUser(await _storage.readActiveUserId());
  }
}

class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.errors = const {},
    this.data = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, dynamic> errors;
  final Map<String, dynamic> data;

  factory ApiException.fromDio(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException(
        'The request timed out. Please check your connection and try again.',
        statusCode: error.response?.statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        'No internet connection or the server is unreachable. Please check your connection and try again.',
        statusCode: error.response?.statusCode,
      );
    }

    final data = error.response?.data;
    final statusCode = error.response?.statusCode;
    if (data is Map) {
      final body = Map<String, dynamic>.from(data);
      final responseCode = body['code']?.toString();
      final errors = Map<String, dynamic>.from(
        body['errors'] is Map ? body['errors'] as Map : {},
      );
      final extraData = Map<String, dynamic>.from(
        body['data'] is Map ? body['data'] as Map : {},
      );
      if (responseCode != null && responseCode.isNotEmpty) {
        extraData['code'] = responseCode;
      }
      final rawMessage = body['message']?.toString();
      final friendlyRawMessage = _friendlyMessage(rawMessage, statusCode);
      final validationMessage = responseCode == null || responseCode.isEmpty
          ? _validationMessage(errors)
          : null;
      final message = _shouldPreferValidationMessage(rawMessage)
          ? validationMessage ?? friendlyRawMessage
          : friendlyRawMessage;
      return ApiException(
        message,
        statusCode: statusCode,
        errors: errors,
        data: extraData,
      );
    }

    return ApiException(
      _friendlyMessage(error.message, statusCode),
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}

String? _validationMessage(Map<String, dynamic> errors) {
  if (errors.isEmpty) return null;
  final messages = errors.values
      .expand((value) {
        if (value is List) return value.map((item) => item.toString());
        return [value.toString()];
      })
      .where((message) => message.trim().isNotEmpty);
  return messages.isEmpty
      ? 'Please check the form and try again.'
      : messages.first;
}

String _friendlyMessage(String? rawMessage, int? statusCode) {
  final message = rawMessage?.trim() ?? '';
  final lower = message.toLowerCase();

  if (statusCode == 401 || statusCode == 419) {
    return 'Your session has expired. Please login again.';
  }

  if (lower ==
      'face recognition service authentication failed. please contact the administrator.') {
    return 'Face recognition service authentication failed. Please contact the administrator.';
  }

  if (lower.contains('python') ||
      lower.contains('face recognition service') ||
      lower.contains('connection refused') ||
      lower.contains('failed to connect')) {
    return 'Face recognition service is currently unavailable. Please try again or contact the administrator.';
  }

  if (_looksTechnical(message)) {
    if (lower.contains('verification') || lower.contains('face')) {
      return 'Verification failed due to a server issue. Please try again or contact admin.';
    }
    return 'A server issue occurred. Please try again or contact admin.';
  }

  if (statusCode == 422) {
    return message.isEmpty ? 'Please check your input and try again.' : message;
  }

  if (statusCode != null && statusCode >= 500) {
    return 'A server issue occurred. Please try again or contact admin.';
  }

  return message.isEmpty ? 'Request failed. Please try again.' : message;
}

bool _looksTechnical(String message) {
  final lower = message.toLowerCase();
  return lower.contains('sqlstate') ||
      lower.contains('queryexception') ||
      lower.contains('stack trace') ||
      lower.contains('integrity constraint') ||
      lower.contains('select * from') ||
      lower.contains('insert into') ||
      lower.contains('update `') ||
      lower.contains(' at ') && lower.contains('.php:');
}

bool _shouldPreferValidationMessage(String? rawMessage) {
  final message = rawMessage?.trim().toLowerCase() ?? '';
  return message.isEmpty || message == 'the given data was invalid.';
}
