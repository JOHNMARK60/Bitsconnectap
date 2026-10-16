import 'package:bits_mobile_app/models/event_model.dart';

class EventTimeline {
  const EventTimeline({
    required this.currentEvents,
    required this.recentEvents,
    required this.upcomingEvents,
  });

  final List<EventModel> currentEvents;
  final List<EventModel> recentEvents;
  final List<EventModel> upcomingEvents;

  factory EventTimeline.fromEvents(
    Iterable<EventModel> events, {
    DateTime? now,
  }) {
    final referenceTime = now ?? campusNow();
    final eventList = events.where((event) => event.id != 0).toList();
    final currentEvents =
        eventList.where((event) => event.isAvailableAt(referenceTime)).toList()
          ..sort((a, b) => _compareCurrentEvents(a, b, referenceTime));
    final recentEvents =
        eventList.where((event) => event.isRecentAt(referenceTime)).toList()
          ..sort(
            (a, b) => _compareNullableDateDesc(a.timelineEnd, b.timelineEnd),
          );
    final upcomingEvents =
        eventList.where((event) => event.isUpcomingAt(referenceTime)).toList()
          ..sort(
            (a, b) => _compareNullableDateAsc(a.timelineStart, b.timelineStart),
          );

    return EventTimeline(
      currentEvents: currentEvents,
      recentEvents: recentEvents,
      upcomingEvents: upcomingEvents,
    );
  }

  static DateTime campusNow() {
    final campusClock = DateTime.now().toUtc().add(const Duration(hours: 8));

    return DateTime(
      campusClock.year,
      campusClock.month,
      campusClock.day,
      campusClock.hour,
      campusClock.minute,
      campusClock.second,
      campusClock.millisecond,
      campusClock.microsecond,
    );
  }

  static int _compareCurrentEvents(EventModel a, EventModel b, DateTime now) {
    final aOngoing = a.isOngoingAt(now);
    final bOngoing = b.isOngoingAt(now);
    if (aOngoing != bOngoing) return aOngoing ? -1 : 1;

    final aDate = aOngoing ? a.timelineEnd : a.timelineStart;
    final bDate = bOngoing ? b.timelineEnd : b.timelineStart;

    return _compareNullableDateAsc(aDate, bDate);
  }

  static int _compareNullableDateAsc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  static int _compareNullableDateDesc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}

extension EventTimelineDates on EventModel {
  DateTime? get scheduleDate =>
      _parseDateOnly(eventDate) ??
      _parseDateOnly(loginDateTime) ??
      _parseDateOnly(attendanceStartTime);

  DateTime? get timelineStart =>
      _parseDateTime(loginDateTime) ??
      _parseDateTime(attendanceStartTime) ??
      _parseDateOnly(eventDate);

  DateTime? get timelineEnd =>
      _parseDateTime(logoutDateTime)?.endOfMinute ??
      _parseDateTime(attendanceEndTime)?.endOfMinute ??
      _endOfDate(eventDate);

  bool hasEndedAt(DateTime now) {
    if (!attendanceEnabled || normalizedAttendancePhase == 'closed') {
      return true;
    }
    final end = timelineEnd;
    return end != null && !end.isAfter(now);
  }

  bool isAvailableAt(DateTime now) {
    final date = scheduleDate;
    if (date == null || !_isSameDate(date, now)) return false;
    return attendanceEnabled && !hasEndedAt(now);
  }

  bool isRecentAt(DateTime now) {
    final date = scheduleDate;
    if (date == null) return hasEndedAt(now);

    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today)) return true;
    if (_isSameDate(date, today)) return hasEndedAt(now);
    return false;
  }

  bool isUpcomingAt(DateTime now) {
    final date = scheduleDate;
    if (date == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
  }

  bool isOngoingAt(DateTime now) {
    final start = timelineStart;
    final end = timelineEnd;
    final hasStarted = start == null || !start.isAfter(now);
    final hasNotEnded = end == null || end.isAfter(now);
    return hasStarted && hasNotEnded;
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime? _parseDateTime(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;

  if (parsed.isUtc || RegExp(r'(Z|[+-]\d\d:?\d\d)$').hasMatch(text)) {
    final campusClock = parsed.toUtc().add(const Duration(hours: 8));

    return DateTime(
      campusClock.year,
      campusClock.month,
      campusClock.day,
      campusClock.hour,
      campusClock.minute,
      campusClock.second,
      campusClock.millisecond,
      campusClock.microsecond,
    );
  }

  return parsed;
}

DateTime? _parseDateOnly(String? value) {
  final parsed = _parseDateTime(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _endOfDate(String? value) {
  final parsed = _parseDateOnly(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
}

extension on DateTime {
  DateTime get endOfMinute =>
      DateTime(year, month, day, hour, minute, 59, 999, 999);
}
