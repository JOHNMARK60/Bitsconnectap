import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// A user-facing failure raised while obtaining an attendance location.
class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A reusable service for handling all location-related functionalities.
///
/// This service centralizes the logic for checking service availability,
/// handling permissions, and fetching the device's current GPS location.
class LocationService {
  /// Retrieves the current geographical position of the device with high accuracy.
  ///
  /// This method orchestrates the entire location validation flow:
  /// 1. Checks if location services are enabled on the device.
  /// 2. Verifies and requests location permissions if not already granted.
  /// 3. Handles cases where permissions are permanently denied.
  /// 4. Fetches the current position using high accuracy.
  ///
  /// Throws descriptive exceptions for different failure scenarios,
  /// which can be caught to display user-friendly messages.
  Future<Position> getCurrentLocation() async {
    final bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (error) {
      debugPrint('Unable to check whether GPS is available: $error');
      throw const LocationServiceException(
        'GPS is currently unavailable. Please try again.',
      );
    }

    if (!serviceEnabled) {
      debugPrint('GPS disabled: location services are not enabled.');
      throw const LocationServiceException(
        'Location services are disabled. Please enable GPS to continue.',
      );
    }

    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
    } catch (error) {
      debugPrint('Unable to determine location permission: $error');
      throw const LocationServiceException(
        'Unable to check location permission. Please try again.',
      );
    }

    if (permission == LocationPermission.denied) {
      debugPrint('Permission denied: requesting location permission.');
      try {
        permission = await Geolocator.requestPermission();
      } catch (error) {
        debugPrint('Location permission request failed: $error');
        throw const LocationServiceException(
          'Unable to request location permission. Please try again.',
        );
      }

      if (permission == LocationPermission.denied) {
        debugPrint('Permission denied: the user declined location access.');
        throw const LocationServiceException(
          'Location permission is required to record attendance.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Permission denied forever: location access is blocked.');
      throw const LocationServiceException(
        'Location permission has been permanently denied. Please enable it in device settings.',
      );
    }

    if (permission == LocationPermission.unableToDetermine) {
      debugPrint(
        'GPS unavailable: location permission could not be determined.',
      );
      throw const LocationServiceException(
        'GPS is currently unavailable. Please try again.',
      );
    }

    debugPrint('Location permission granted; retrieving GPS position.');
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (error) {
      debugPrint('Location retrieval failure: $error');
      throw const LocationServiceException(
        'Unable to determine your location. Please try again.',
      );
    }
  }
}
