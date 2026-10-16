import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/models/user_model.dart';

class AttendedEventModel {
  const AttendedEventModel({
    required this.id,
    this.loginTime,
    this.logoutTime,
    this.scannedTime,
    this.status,
    this.event,
    this.studentName,
    this.studentId,
    this.courseSection,
    this.attendanceMethod,
    this.qrFallbackReason,
    this.qrFallbackOtherReason,
    this.voidReason,
    this.voidedAt,
    this.voidedByName,
    this.isLate = false,
    this.lateMinutes,
    this.lateReason,
  });

  final int id;
  final String? loginTime;
  final String? logoutTime;
  final String? scannedTime;
  final String? status;
  final EventModel? event;
  final String? studentName;
  final String? studentId;
  final String? courseSection;
  final String? attendanceMethod;
  final String? qrFallbackReason;
  final String? qrFallbackOtherReason;
  final String? voidReason;
  final String? voidedAt;
  final String? voidedByName;
  final bool isLate;
  final int? lateMinutes;
  final String? lateReason;

  /// Order by when attendance was recorded, falling back to the event schedule.
  DateTime? get attendedAt =>
      DateTime.tryParse(loginTime ?? '') ??
      DateTime.tryParse(scannedTime ?? '') ??
      DateTime.tryParse(event?.loginDateTime ?? '') ??
      DateTime.tryParse(event?.eventDate ?? '');

  static int compareNewestFirst(AttendedEventModel a, AttendedEventModel b) {
    final aDate = a.attendedAt;
    final bDate = b.attendedAt;
    if (aDate == null && bDate != null) return 1;
    if (aDate != null && bDate == null) return -1;
    final dateOrder = aDate == null ? 0 : bDate!.compareTo(aDate);
    return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
  }

  factory AttendedEventModel.fromJson(Map<String, dynamic> json) {
    final event = json['event'] is Map
        ? Map<String, dynamic>.from(json['event'] as Map)
        : json['event_data'] is Map
        ? Map<String, dynamic>.from(json['event_data'] as Map)
        : const <String, dynamic>{};
    final student = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : const <String, dynamic>{};
    final user = student['user'] is Map
        ? Map<String, dynamic>.from(student['user'] as Map)
        : student;
    final details = student['details'] is Map
        ? Map<String, dynamic>.from(student['details'] as Map)
        : student['other_detail'] is Map
        ? Map<String, dynamic>.from(student['other_detail'] as Map)
        : user['details'] is Map
        ? Map<String, dynamic>.from(user['details'] as Map)
        : const <String, dynamic>{};
    final attendanceStatus = json['attendance_status']?.toString();
    final rowStatus = json['status']?.toString();

    return AttendedEventModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      loginTime:
          json['login_time']?.toString() ??
          json['time_in']?.toString() ??
          json['check_in']?.toString(),
      logoutTime:
          json['logout_time']?.toString() ??
          json['time_out']?.toString() ??
          json['check_out']?.toString(),
      scannedTime:
          json['scanned_time']?.toString() ??
          json['scanned_at']?.toString() ??
          json['updated_at']?.toString() ??
          json['created_at']?.toString(),
      status: attendanceStatus == 'voided'
          ? attendanceStatus
          : rowStatus ?? attendanceStatus ?? json['action']?.toString(),
      event: event.isNotEmpty ? EventModel.fromJson(event) : null,
      studentName:
          json['student_name']?.toString() ??
          displayName(user, fallback: 'Student Record'),
      studentId:
          details['idnumber']?.toString() ??
          details['student_id']?.toString() ??
          user['student_id']?.toString() ??
          user['idnumber']?.toString(),
      courseSection: _courseSection(details),
      attendanceMethod: json['attendance_method']?.toString(),
      qrFallbackReason: json['qr_fallback_reason']?.toString(),
      qrFallbackOtherReason: json['qr_fallback_other_reason']?.toString(),
      voidReason: json['void_reason']?.toString(),
      voidedAt: json['voided_at']?.toString(),
      voidedByName: json['voided_by_name']?.toString(),
      isLate: _parseBool(json['is_late']),
      lateMinutes: int.tryParse(json['late_minutes']?.toString() ?? ''),
      lateReason: json['late_reason']?.toString(),
    );
  }
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase().trim();
  return text == '1' || text == 'true' || text == 'yes';
}

String? _courseSection(Map<String, dynamic> details) {
  final course = details['course']?.toString();
  final year = details['year']?.toString();
  final section = details['section']?.toString();
  final combined = details['year_section']?.toString();

  final values = [
    course,
    combined ??
        [year, section]
            .where((value) => value != null && value.trim().isNotEmpty)
            .join(' - '),
  ].where((value) => value != null && value.trim().isNotEmpty).toList();

  return values.isEmpty ? null : values.join(' / ');
}
