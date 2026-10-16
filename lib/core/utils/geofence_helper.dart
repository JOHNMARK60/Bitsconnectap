import 'package:geolocator/geolocator.dart';

/// A helper class for geofencing calculations.
///
/// This class centralizes the event location, allowed radius,
/// and the logic for distance calculation and validation.
class GeofenceHelper {
  /// The latitude of the event location's geofence center.
  static const double eventLatitude = 10.355321079699701;

  /// The longitude of the event location's geofence center.
  static const double eventLongitude = 124.96613355189003;

  /// The allowed radius in meters from the event location.
  static const double allowedRadiusInMeters = 120.0;

  static const String outsideRadiusMessage =
      'You must be within the allowed campus area to record attendance.';

  /// Calculates the distance in meters between the user's location and the event location.
  ///
  /// [latitude] The user's current latitude.
  /// [longitude] The user's current longitude.
  ///
  /// Returns the distance in meters.
  static double calculateDistance(double latitude, double longitude) {
    return calculateDistanceToVenue(latitude, longitude, null);
  }

  static double calculateDistanceToVenue(
    double latitude,
    double longitude,
    Map<String, dynamic>? venue,
  ) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      _number(venue?['latitude'], eventLatitude),
      _number(venue?['longitude'], eventLongitude),
    );
  }

  static double allowedRadiusForVenue(Map<String, dynamic>? venue) =>
      _number(venue?['radius_meters'], allowedRadiusInMeters);

  /// Checks if the user's location is within the allowed radius of the event.
  ///
  /// [latitude] The user's current latitude.
  /// [longitude] The user's current longitude.
  ///
  /// Returns `true` if the user is within the radius, `false` otherwise.
  static bool isWithinRadius(double latitude, double longitude) {
    final double distance = calculateDistance(latitude, longitude);
    return distance <= allowedRadiusInMeters;
  }

  static bool isWithinVenue(
    double latitude,
    double longitude,
    Map<String, dynamic>? venue,
  ) {
    return calculateDistanceToVenue(latitude, longitude, venue) <=
        allowedRadiusForVenue(venue);
  }

  static double _number(Object? value, double fallback) {
    return value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? fallback;
  }
}
