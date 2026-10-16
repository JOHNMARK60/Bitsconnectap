import 'package:bits_mobile_app/controllers/scanner_controller.dart';
import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/core/services/location_service.dart';
import 'package:bits_mobile_app/core/utils/geofence_helper.dart';
import 'package:bits_mobile_app/models/scan_result_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'scanner_controller_test.mocks.dart';

@GenerateMocks([ApiService, LocationService])
void main() {
  late ScannerController scannerController;
  late MockApiService mockApiService;
  late MockLocationService mockLocationService;

  const qrCode = 'test_qr_code';
  const eventId = 1;

  Position positionAt({required double latitude, required double longitude}) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 1,
      headingAccuracy: 1,
    );
  }

  double latitudeNorthBy(double meters) {
    const metersPerDegreeLatitude = 111320.0;
    return GeofenceHelper.eventLatitude + meters / metersPerDegreeLatitude;
  }

  setUp(() {
    mockApiService = MockApiService();
    mockLocationService = MockLocationService();
    scannerController = ScannerController(mockApiService, mockLocationService);
  });

  group('GeofenceHelper', () {
    test('uses the specified venue and 120-meter radius', () {
      expect(GeofenceHelper.eventLatitude, 10.355321079699701);
      expect(GeofenceHelper.eventLongitude, 124.96613355189003);
      expect(GeofenceHelper.allowedRadiusInMeters, 120);
    });

    test('accepts a position approximately 40 meters away', () {
      expect(
        GeofenceHelper.isWithinRadius(
          latitudeNorthBy(40),
          GeofenceHelper.eventLongitude,
        ),
        isTrue,
      );
    });

    test('rejects a position approximately 121 meters away', () {
      expect(
        GeofenceHelper.isWithinRadius(
          latitudeNorthBy(121),
          GeofenceHelper.eventLongitude,
        ),
        isFalse,
      );
    });
  });

  group('ScannerController geofence validation', () {
    test('rejects a concurrent attendance submission before it reaches the API',
        () async {
      final response = Completer<Map<String, dynamic>>();
      final position = positionAt(
        latitude: GeofenceHelper.eventLatitude,
        longitude: GeofenceHelper.eventLongitude,
      );
      when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => position);
      when(mockApiService.post(any, any)).thenAnswer((_) => response.future);
      when(
        mockApiService.get(
          '/mobile/scanner/scan-history',
          cacheDuration: anyNamed('cacheDuration'),
          forceRefresh: anyNamed('forceRefresh'),
        ),
      ).thenAnswer((_) async => {
            'data': {'scan_history': <dynamic>[]},
          });

      final firstRequest = scannerController.scan(qrCode, eventId);
      await Future<void>.delayed(Duration.zero);
      final secondResult = await scannerController.scan(qrCode, eventId);

      expect(secondResult.status, 'error');
      expect(secondResult.message, contains('already being processed'));
      verify(mockApiService.post('/mobile/scanner/scan', any)).called(1);

      response.complete({
        'success': true,
        'message': 'Attendance recorded successfully.',
        'data': {'status': 'logged_in'},
      });
      await firstRequest;
    });

    test(
      'submits all required location fields when inside the radius',
      () async {
        final position = positionAt(
          latitude: GeofenceHelper.eventLatitude,
          longitude: GeofenceHelper.eventLongitude,
        );
        when(
          mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => position);
        when(mockApiService.post(any, any)).thenAnswer(
          (_) async => {
            'success': true,
            'message': 'Attendance recorded successfully.',
            'data': {'status': 'logged_in'},
          },
        );
        when(
          mockApiService.get(
            '/mobile/scanner/scan-history',
            cacheDuration: anyNamed('cacheDuration'),
            forceRefresh: anyNamed('forceRefresh'),
          ),
        ).thenAnswer(
          (_) async => {
            'data': {'scan_history': <dynamic>[]},
          },
        );

        final ScanResultModel result = await scannerController.scan(
          qrCode,
          eventId,
        );

        expect(result.message, 'Attendance recorded successfully.');
        expect(result.status, 'logged_in');
        final payload =
            verify(
                  mockApiService.post('/mobile/scanner/scan', captureAny),
                ).captured.single
                as Map<String, dynamic>;
        expect(payload.keys, {
          'event_id',
          'qr_code',
          'confirmed_present',
          'latitude',
          'longitude',
          'distance',
        });
        expect(payload['event_id'], eventId);
        expect(payload['qr_code'], qrCode);
        expect(payload['confirmed_present'], isTrue);
        expect(payload['latitude'], GeofenceHelper.eventLatitude);
        expect(payload['longitude'], GeofenceHelper.eventLongitude);
        expect(payload['distance'], closeTo(0, 0.01));
      },
    );

    test('does not submit attendance when outside the radius', () async {
      when(mockLocationService.getCurrentLocation()).thenAnswer(
        (_) async => positionAt(
          latitude: latitudeNorthBy(121),
          longitude: GeofenceHelper.eventLongitude,
        ),
      );

      final result = await scannerController.scan(qrCode, eventId);

      expect(result.status, 'error');
      expect(result.message, GeofenceHelper.outsideRadiusMessage);
      verifyNever(mockApiService.post(any, any));
    });

    for (final failure in <LocationServiceException>[
      const LocationServiceException(
        'Location services are disabled. Please enable GPS to continue.',
      ),
      const LocationServiceException(
        'Location permission is required to record attendance.',
      ),
      const LocationServiceException(
        'Location permission has been permanently denied. Please enable it in device settings.',
      ),
    ]) {
      test('does not submit when location fails: ${failure.message}', () async {
        when(mockLocationService.getCurrentLocation()).thenThrow(failure);

        final result = await scannerController.scan(qrCode, eventId);

        expect(result.status, 'error');
        expect(result.message, failure.message);
        verifyNever(mockApiService.post(any, any));
      });
    }
  });
}
import 'dart:async';
