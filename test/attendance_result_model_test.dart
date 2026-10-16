import 'package:bits_mobile_app/models/attendance_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses recognized student details for face-attendance feedback', () {
    final result = AttendanceResultModel.fromJson({
      'success': true,
      'message': 'Attendance recorded successfully.',
      'data': {
        'recognized': true,
        'student': {
          'name': 'Student User',
          'student_id': '2310150-1',
          'course': 'BSIT',
          'year_level': '3rd',
          'section': 'B',
        },
        'event': {'name': 'Campus Event'},
      },
    });

    expect(result.success, isTrue);
    expect(result.studentName, 'Student User');
    expect(result.studentId, '2310150-1');
    expect(result.course, 'BSIT');
    expect(result.yearLevel, '3rd');
    expect(result.section, 'B');
    expect(result.eventName, 'Campus Event');
  });

  test('preserves exact Laravel duplicate attendance messages', () {
    const timeIn =
        'Your Time-In has already been recorded. Please wait until the administrator opens Time-Out.';
    const timeOut = 'Your attendance for this event is already complete.';
    expect(
      AttendanceResultModel.fromJson({
        'success': false,
        'message': timeIn,
      }).message,
      timeIn,
    );
    expect(
      AttendanceResultModel.fromJson({
        'success': false,
        'message': timeOut,
      }).message,
      timeOut,
    );
    expect(
      AttendanceResultModel.fromJson({
        'success': false,
        'message': timeOut,
        'data': {'already_attended': true},
      }).message,
      timeOut,
    );
  });
}
