import 'dart:io';

import 'package:bits_mobile_app/core/constants/api_config.dart';
import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  AppUpdateService(this._api);

  final ApiService _api;

  Future<AppUpdate?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;

    try {
      final response = await _api.get('/app-update');
      final data = Map<String, dynamic>.from(response['data'] as Map? ?? {});
      final latestVersion = data['latest_version']?.toString().trim() ?? '';
      final downloadUrl = data['download_url']?.toString().trim() ?? '';

      if (latestVersion.isEmpty ||
          downloadUrl.isEmpty ||
          !_isNewer(latestVersion, ApiConfig.versionLabel)) {
        return null;
      }

      return AppUpdate(
        latestVersion: latestVersion,
        downloadUrl: Uri.tryParse(downloadUrl),
        required:
            data['required'] == true || data['required'].toString() == '1',
        message: data['message']?.toString().trim(),
      );
    } catch (_) {
      // Update checks must never prevent normal app use when offline.
      return null;
    }
  }

  Future<bool> openUpdate(AppUpdate update) async {
    final url = update.downloadUrl;
    if (url == null || !url.hasScheme) return false;
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

class AppUpdate {
  const AppUpdate({
    required this.latestVersion,
    required this.downloadUrl,
    required this.required,
    this.message,
  });

  final String latestVersion;
  final Uri? downloadUrl;
  final bool required;
  final String? message;
}

bool _isNewer(String candidate, String current) {
  List<int> parts(String value) => value
      .replaceFirst(RegExp(r'^v', caseSensitive: false), '')
      .split(RegExp(r'[.+-]'))
      .map((part) => int.tryParse(part) ?? 0)
      .toList();

  final candidateParts = parts(candidate);
  final currentParts = parts(current);
  final length = candidateParts.length > currentParts.length
      ? candidateParts.length
      : currentParts.length;
  for (var index = 0; index < length; index++) {
    final candidatePart = index < candidateParts.length
        ? candidateParts[index]
        : 0;
    final currentPart = index < currentParts.length ? currentParts[index] : 0;
    if (candidatePart != currentPart) return candidatePart > currentPart;
  }
  return false;
}
