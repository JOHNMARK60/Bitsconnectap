import 'package:bits_mobile_app/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._storage);

  final SecureStorageService _storage;
  bool darkMode = false;

  Future<void> load() async {
    darkMode = await _storage.readDarkMode();
    notifyListeners();
  }

  Future<void> toggle() async {
    darkMode = !darkMode;
    await _storage.saveDarkMode(darkMode);
    notifyListeners();
  }
}
