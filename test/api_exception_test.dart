import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ApiException faceError(int statusCode, String message) {
    final request = RequestOptions(path: '/mobile/student/attendance/face');
    return ApiException.fromDio(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: statusCode,
          data: {'success': false, 'message': message},
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  test('face API key failure remains distinct from service downtime', () {
    final exception = faceError(
      502,
      'Face recognition service authentication failed. Please contact the administrator.',
    );
    expect(exception.statusCode, 502);
    expect(
      exception.message,
      'Face recognition service authentication failed. Please contact the administrator.',
    );
  });

  test('unavailable face service does not assume the process is stopped', () {
    final exception = faceError(
      503,
      'Face recognition service is currently unavailable.',
    );
    expect(
      exception.message,
      'Face recognition service is currently unavailable. Please try again or contact the administrator.',
    );
  });

  test('mobile session expiration still requests login', () {
    expect(
      faceError(401, 'Unauthenticated.').message,
      'Your session has expired. Please login again.',
    );
  });

  test('preserves Laravel duplicate message over metadata booleans', () {
    final exception = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/mobile/student/attendance/face'),
        response: Response(
          requestOptions: RequestOptions(
            path: '/mobile/student/attendance/face',
          ),
          statusCode: 409,
          data: {
            'success': false,
            'message':
                'Your Time-In has already been recorded. Please wait until the administrator opens Time-Out.',
            'data': {'allowed': false, 'reason': 'time_in_already_recorded'},
            'errors': {'allowed': false, 'reason': 'time_in_already_recorded'},
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      exception.message,
      'Your Time-In has already been recorded. Please wait until the administrator opens Time-Out.',
    );
  });
}
