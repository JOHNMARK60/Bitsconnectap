import 'package:bits_mobile_app/models/event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses attendance mode and enabled status from Laravel payload', () {
    final timeOutOpen = EventModel.fromJson({
      'id': 1,
      'name': 'General Assembly',
      'attendance_enabled': true,
      'attendance_mode': 'time_out',
      'attendance_status': 'time_in_closed',
      'attendance_status_message': 'Time-Out attendance is currently open.',
    });

    expect(timeOutOpen.isAttendancePhaseOpen, isTrue);
    expect(timeOutOpen.isTimeOutPhase, isTrue);
    expect(timeOutOpen.attendanceModeDisplay, 'Time-Out');
    expect(timeOutOpen.attendanceOpenDisplay, 'Open');
    expect(
      timeOutOpen.attendancePhaseMessage,
      'Time-Out attendance is currently open.',
    );

    final timeInClosed = EventModel.fromJson({
      'id': 2,
      'name': 'General Assembly',
      'attendance_enabled': false,
      'attendance_mode': 'time_in',
      'attendance_status_message': 'Time-In attendance is currently closed.',
    });

    expect(timeInClosed.isAttendancePhaseOpen, isFalse);
    expect(timeInClosed.attendanceModeDisplay, 'Time-In');
    expect(timeInClosed.attendanceOpenDisplay, 'Closed');
    expect(
      timeInClosed.attendancePhaseMessage,
      'Time-In attendance is currently closed.',
    );
  });
}
