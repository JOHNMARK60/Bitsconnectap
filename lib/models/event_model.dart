class EventModel {
  const EventModel({
    required this.id,
    required this.name,
    this.description,
    this.eventDate,
    this.loginDateTime,
    this.logoutDateTime,
    this.attendanceStartTime,
    this.attendanceEndTime,
    this.academicYear,
    this.semester,
    this.attendanceStatus,
    this.updatedAt,
    this.attendanceEnabled = true,
    this.attendanceMode,
    this.attendanceStatusMessage,
    this.eventAttendanceStatus,
    this.attendancePhase,
    this.attendancePhaseLabel,
    this.attendanceAction,
    this.attendanceMessage,
    this.qrEnabled = true,
    this.scannerEnabled = true,
    this.attendanceWindow,
    this.attendanceVenue,
  });

  final int id;
  final String name;
  final String? description;
  final String? eventDate;
  final String? loginDateTime;
  final String? logoutDateTime;
  final String? attendanceStartTime;
  final String? attendanceEndTime;
  final String? academicYear;
  final String? semester;
  final String? attendanceStatus;
  final String? updatedAt;
  final bool attendanceEnabled;
  final String? attendanceMode;
  final String? attendanceStatusMessage;
  final String? eventAttendanceStatus;
  final String? attendancePhase;
  final String? attendancePhaseLabel;
  final String? attendanceAction;
  final String? attendanceMessage;
  final bool qrEnabled;
  final bool scannerEnabled;
  final Map<String, dynamic>? attendanceWindow;
  final Map<String, dynamic>? attendanceVenue;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final attendance = json['attendance'];
    return EventModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name:
          json['name']?.toString() ??
          json['title']?.toString() ??
          json['event_title']?.toString() ??
          'Untitled event',
      description:
          json['short_description']?.toString() ??
          json['description']?.toString(),
      eventDate:
          json['event_date']?.toString() ??
          json['date']?.toString() ??
          json['event_datetime']?.toString(),
      loginDateTime:
          json['login_datetime']?.toString() ??
          json['login_time']?.toString() ??
          json['start_time']?.toString(),
      logoutDateTime:
          json['logout_datetime']?.toString() ??
          json['logout_time']?.toString() ??
          json['end_time']?.toString(),
      attendanceStartTime: json['attendance_start_time']?.toString(),
      attendanceEndTime: json['attendance_end_time']?.toString(),
      academicYear: json['academic_year']?.toString(),
      semester: json['semester']?.toString(),
      attendanceStatus: attendance is Map
          ? attendance['status']?.toString()
          : json['attendance_status']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      attendanceEnabled: _boolValue(json['attendance_enabled'], fallback: true),
      attendanceMode: json['attendance_mode']?.toString(),
      attendanceStatusMessage: json['attendance_status_message']?.toString(),
      eventAttendanceStatus: json['attendance_status']?.toString(),
      attendancePhase:
          json['attendance_phase']?.toString() ??
          json['attendance_status']?.toString(),
      attendancePhaseLabel: json['attendance_phase_label']?.toString(),
      attendanceAction: json['attendance_action']?.toString(),
      attendanceMessage: json['attendance_message']?.toString(),
      qrEnabled: _boolValue(json['qr_enabled'], fallback: true),
      scannerEnabled: _boolValue(json['scanner_enabled'], fallback: true),
      attendanceWindow: json['attendance_window'] is Map
          ? Map<String, dynamic>.from(json['attendance_window'] as Map)
          : null,
      attendanceVenue: json['attendance_venue'] is Map
          ? Map<String, dynamic>.from(json['attendance_venue'] as Map)
          : null,
    );
  }

  String get normalizedAttendancePhase {
    final status = (attendancePhase ?? eventAttendanceStatus ?? '')
        .trim()
        .toLowerCase();

    switch (status) {
      case 'time_in_open':
      case 'time_in_closed':
      case 'time_out_open':
      case 'closed':
      case 'not_open':
        return status;
      case 'open':
        return 'time_in_open';
      case 'scheduled':
        return 'not_open';
      case 'ended':
        return 'closed';
      default:
        return 'not_open';
    }
  }

  bool get isAttendancePhaseOpen =>
      attendanceEnabled &&
      (normalizedAttendanceMode == 'time_in' ||
          normalizedAttendanceMode == 'time_out');

  bool get isTimeOutPhase => normalizedAttendanceMode == 'time_out';

  String get normalizedAttendanceMode {
    final mode = (attendanceMode ?? '').trim().toLowerCase();
    if (mode == 'time_in' || mode == 'time_out') return mode;
    return normalizedAttendancePhase == 'time_out_open'
        ? 'time_out'
        : 'time_in';
  }

  String get attendanceModeDisplay =>
      normalizedAttendanceMode == 'time_out' ? 'Time-Out' : 'Time-In';

  String get attendanceOpenDisplay => attendanceEnabled ? 'Open' : 'Closed';

  String get attendancePhaseDisplay {
    if (attendanceStatusMessage != null &&
        attendanceStatusMessage!.trim().isNotEmpty) {
      return attendanceStatusMessage!;
    }

    if (attendancePhaseLabel != null &&
        attendancePhaseLabel!.trim().isNotEmpty) {
      return attendancePhaseLabel!;
    }

    switch (normalizedAttendancePhase) {
      case 'time_in_open':
        return 'Time-In Open';
      case 'time_in_closed':
        return 'Time-In Closed';
      case 'time_out_open':
        return 'Time-Out Open';
      case 'closed':
        return 'Closed';
      default:
        return 'Not Open';
    }
  }

  String get attendanceActionDisplay => isTimeOutPhase ? 'Time Out' : 'Time In';

  bool get attendanceWasExtended => attendanceWindow?['extended'] == true;

  String? get attendanceWindowEnd => attendanceWindow?['end']?.toString();

  String get attendanceVenueLabel =>
      attendanceVenue?['label']?.toString() ?? 'Approved campus venue';

  String get attendancePhaseMessage {
    if (attendanceStatusMessage != null &&
        attendanceStatusMessage!.trim().isNotEmpty) {
      return attendanceStatusMessage!;
    }

    if (!attendanceEnabled) {
      return 'Attendance is currently unavailable. Please wait for the administrator to open it.';
    }

    if (attendanceMessage != null && attendanceMessage!.trim().isNotEmpty) {
      return attendanceMessage!;
    }

    switch (normalizedAttendancePhase) {
      case 'time_in_open':
        return 'Time-in is open.';
      case 'time_in_closed':
        return 'Time-In is closed. Please wait until the administrator opens Time-Out.';
      case 'time_out_open':
        return 'Time-out is open.';
      case 'closed':
        return 'Attendance for this event is already closed.';
      default:
        return 'Attendance is not open yet.';
    }
  }
}

bool _boolValue(Object? value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final text = value.toString().trim().toLowerCase();
  if (text == '1' || text == 'true' || text == 'yes' || text == 'on') {
    return true;
  }
  if (text == '0' || text == 'false' || text == 'no' || text == 'off') {
    return false;
  }
  return fallback;
}
