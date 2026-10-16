class AttendanceResultModel {
  const AttendanceResultModel({
    required this.success,
    required this.message,
    this.studentName,
    this.studentId,
    this.course,
    this.yearLevel,
    this.section,
    this.courseYear,
    this.eventName,
    this.attendanceStatus,
    this.recognized = false,
    this.alreadyAttended = false,
    this.recordedTime,
    this.similarityScore,
    this.threshold,
    this.geotagDistance,
    this.geotagStatus,
    this.staticIpStatus,
    this.developerOptionsEnabled,
    this.code,
    this.registrationRequired = false,
  });

  final bool success;
  final String message;
  final String? studentName;
  final String? studentId;
  final String? course;
  final String? yearLevel;
  final String? section;
  final String? courseYear;
  final String? eventName;
  final String? attendanceStatus;
  final bool recognized;
  final bool alreadyAttended;
  final String? recordedTime;
  final double? similarityScore;
  final double? threshold;
  final double? geotagDistance;
  final String? geotagStatus;
  final String? staticIpStatus;
  final bool? developerOptionsEnabled;
  final String? code;
  final bool registrationRequired;

  factory AttendanceResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final student = data['student'] is Map
        ? Map<String, dynamic>.from(data['student'] as Map)
        : const <String, dynamic>{};
    final event = data['event'] is Map
        ? Map<String, dynamic>.from(data['event'] as Map)
        : const <String, dynamic>{};
    final attendance = data['attendance'] is Map
        ? Map<String, dynamic>.from(data['attendance'] as Map)
        : const <String, dynamic>{};
    final recognition = data['recognition'] is Map
        ? Map<String, dynamic>.from(data['recognition'] as Map)
        : const <String, dynamic>{};
    final validation = data['validation'] is Map
        ? Map<String, dynamic>.from(data['validation'] as Map)
        : const <String, dynamic>{};

    final alreadyAttended = data['already_attended'] == true;

    return AttendanceResultModel(
      success:
          !alreadyAttended &&
          (data['success'] == true || json['success'] == true),
      message:
          data['message']?.toString() ??
          json['message']?.toString() ??
          'Attendance processed.',
      studentName:
          student['name']?.toString() ?? data['student_name']?.toString(),
      studentId:
          student['student_id']?.toString() ??
          student['student_id_number']?.toString() ??
          data['student_id_number']?.toString(),
      course: student['course']?.toString(),
      yearLevel:
          student['year_level']?.toString() ?? student['year']?.toString(),
      section: student['section']?.toString(),
      courseYear: _courseYear(student) ?? data['course_year']?.toString(),
      eventName: event['name']?.toString() ?? data['event_name']?.toString(),
      attendanceStatus:
          attendance['status']?.toString() ??
          data['attendance_status']?.toString(),
      recognized: data['recognized'] == true,
      alreadyAttended: alreadyAttended,
      recordedTime:
          attendance['time_out']?.toString() ??
          attendance['logout_time']?.toString() ??
          attendance['time_in']?.toString() ??
          data['recorded_time']?.toString(),
      similarityScore: _toDouble(recognition['similarity_score']),
      threshold: _toDouble(recognition['threshold']),
      geotagDistance:
          _toDouble(validation['geotag_distance']) ??
          _toDouble(data['distance']),
      geotagStatus:
          validation['geotag_status']?.toString() ??
          data['location_validation_status']?.toString(),
      staticIpStatus:
          validation['static_ip_status']?.toString() ??
          data['static_ip_status']?.toString(),
      developerOptionsEnabled: validation['developer_options_enabled'] is bool
          ? validation['developer_options_enabled'] as bool
          : data['developer_options_enabled'] is bool
          ? data['developer_options_enabled'] as bool
          : null,
      code: data['code']?.toString() ?? json['code']?.toString(),
      registrationRequired:
          data['registration_required'] == true ||
          json['registration_required'] == true ||
          data['code']?.toString() == 'FACE_REGISTRATION_REQUIRED' ||
          json['code']?.toString() == 'FACE_REGISTRATION_REQUIRED',
    );
  }
}

String? _courseYear(Map<String, dynamic> student) {
  final course = student['course']?.toString();
  final year = student['year_level']?.toString();
  return [
    course,
    year,
  ].where((value) => value != null && value.trim().isNotEmpty).join(' - ');
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  return double.tryParse(value.toString());
}
