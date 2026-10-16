import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AlumniController extends ChangeNotifier {
  AlumniController(this._api);

  final ApiService _api;
  bool loading = false;
  String? error;
  Map<String, dynamic>? dashboard;
  Map<String, dynamic>? profile;
  Map<String, dynamic>? records;
  List<EventModel> events = [];
  List<Map<String, dynamic>> announcements = [];

  Future<void> loadDashboard() async => _load(() async {
    final response = await _api.get(
      '/mobile/alumni/dashboard',
      cacheDuration: const Duration(minutes: 2),
    );
    dashboard = Map<String, dynamic>.from(response['data'] as Map);
  });

  Future<void> loadProfile() async => _load(() async {
    final response = await _api.get(
      '/mobile/alumni/profile',
      cacheDuration: const Duration(minutes: 15),
    );
    profile = Map<String, dynamic>.from(response['data'] as Map);
  });

  Future<void> loadRecords() async => _load(() async {
    final response = await _api.get(
      '/mobile/alumni/records',
      cacheDuration: const Duration(minutes: 5),
    );
    records = Map<String, dynamic>.from(response['data'] as Map);
  });

  Future<void> loadEvents() async => _load(() async {
    final response = await _api.get(
      '/mobile/alumni/events',
      cacheDuration: const Duration(minutes: 3),
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    events = (data['events'] as List)
        .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  });

  Future<void> loadAnnouncements() async => _load(() async {
    final response = await _api.get(
      '/mobile/alumni/announcements',
      cacheDuration: const Duration(minutes: 2),
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    announcements = (data['announcements'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  });

  Future<String?> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/mobile/alumni/profile', data);
      profile = Map<String, dynamic>.from(response['data'] as Map);
      notifyListeners();
      return response['message']?.toString();
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> submitYearbook({
    required XFile image,
    required String motto,
    required String graduationYear,
  }) async {
    try {
      final response = await _api.postForm(
        '/mobile/alumni/yearbook',
        FormData.fromMap({
          'grad_pic': await MultipartFile.fromFile(
            image.path,
            filename: 'graduation-picture.jpg',
          ),
          'motto': motto,
          'grad_year': graduationYear,
        }),
      );
      await loadRecords();
      return response['message']?.toString();
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> saveWorkExperience({
    int? id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = id == null
          ? await _api.post('/mobile/alumni/work-experiences', data)
          : await _api.put('/mobile/alumni/work-experiences/$id', data);
      await loadRecords();
      return response['message']?.toString();
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteWorkExperience(int id) async {
    try {
      final response = await _api.delete('/mobile/alumni/work-experiences/$id');
      await loadRecords();
      return response['message']?.toString();
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> changePassword(
    String current,
    String password,
    String confirmation,
  ) async {
    try {
      final response = await _api.post('/mobile/alumni/change-password', {
        'current_password': current,
        'new_password': password,
        'new_password_confirmation': confirmation,
      });
      return response['message']?.toString();
    } on ApiException catch (e) {
      return e.message;
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
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
