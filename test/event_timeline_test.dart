import 'package:bits_mobile_app/core/utils/event_timeline.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = '2026-07-04 10:00:00';

  test('groups only active events scheduled today as current', () {
    final timeline = EventTimeline.fromEvents([
      event(
        id: 1,
        name: 'Tomorrow',
        loginDateTime: '2026-07-05 09:00:00',
        logoutDateTime: '2026-07-05 11:00:00',
      ),
      event(
        id: 2,
        name: 'Ended',
        loginDateTime: '2026-07-04 07:00:00',
        logoutDateTime: '2026-07-04 09:00:00',
      ),
      event(
        id: 3,
        name: 'Today Later',
        loginDateTime: '2026-07-04 13:00:00',
        logoutDateTime: '2026-07-04 15:00:00',
      ),
      event(
        id: 4,
        name: 'Ongoing',
        loginDateTime: '2026-07-04 09:00:00',
        logoutDateTime: '2026-07-04 11:00:00',
      ),
    ], now: DateTime.parse(now));

    expect(timeline.currentEvents.map((event) => event.name), [
      'Ongoing',
      'Today Later',
    ]);
    expect(timeline.recentEvents.map((event) => event.name), ['Ended']);
  });

  test('hides future events from current and recent groups', () {
    final timeline = EventTimeline.fromEvents([
      event(
        id: 1,
        name: 'Tomorrow',
        eventDate: '2026-07-05',
        loginDateTime: '2026-07-05 09:00:00',
        logoutDateTime: '2026-07-05 11:00:00',
      ),
    ], now: DateTime.parse(now));

    expect(timeline.currentEvents, isEmpty);
    expect(timeline.recentEvents, isEmpty);
  });

  test('sorts recent events by latest completed first', () {
    final timeline = EventTimeline.fromEvents([
      event(
        id: 1,
        name: 'Older',
        loginDateTime: '2026-07-02 09:00:00',
        logoutDateTime: '2026-07-02 11:00:00',
      ),
      event(
        id: 2,
        name: 'Latest',
        loginDateTime: '2026-07-04 07:00:00',
        logoutDateTime: '2026-07-04 09:00:00',
      ),
      event(
        id: 3,
        name: 'Middle',
        loginDateTime: '2026-07-03 12:00:00',
        logoutDateTime: '2026-07-03 13:00:00',
      ),
    ], now: DateTime.parse(now));

    expect(timeline.recentEvents.map((event) => event.name), [
      'Latest',
      'Middle',
      'Older',
    ]);
    expect(timeline.currentEvents, isEmpty);
  });

  test('uses event date end of day when no end time is available', () {
    final timeline = EventTimeline.fromEvents([
      event(id: 1, name: 'Today Date Only', eventDate: '2026-07-04'),
      event(id: 2, name: 'Yesterday Date Only', eventDate: '2026-07-03'),
    ], now: DateTime.parse(now));

    expect(timeline.currentEvents.map((event) => event.name), [
      'Today Date Only',
    ]);
    expect(timeline.recentEvents.map((event) => event.name), [
      'Yesterday Date Only',
    ]);
  });

  test('keeps an event current through the full logout minute', () {
    final duringLogoutMinute = EventTimeline.fromEvents([
      event(
        id: 1,
        name: 'Logout Minute',
        loginDateTime: '2026-07-06 08:13:00',
        logoutDateTime: '2026-07-06 08:35:00',
      ),
    ], now: DateTime.parse('2026-07-06 08:35:30'));

    expect(duringLogoutMinute.currentEvents.map((event) => event.name), [
      'Logout Minute',
    ]);
    expect(duringLogoutMinute.recentEvents, isEmpty);

    final afterLogoutMinute = EventTimeline.fromEvents([
      event(
        id: 1,
        name: 'Logout Minute',
        loginDateTime: '2026-07-06 08:13:00',
        logoutDateTime: '2026-07-06 08:35:00',
      ),
    ], now: DateTime.parse('2026-07-06 08:36:00'));

    expect(afterLogoutMinute.currentEvents, isEmpty);
    expect(afterLogoutMinute.recentEvents.map((event) => event.name), [
      'Logout Minute',
    ]);
  });

  test('moves closed events scheduled today to recent events', () {
    final timeline = EventTimeline.fromEvents([
      event(
        id: 1,
        name: 'Closed Today',
        eventDate: '2026-07-04',
        attendancePhase: 'closed',
      ),
    ], now: DateTime.parse(now));

    expect(timeline.currentEvents, isEmpty);
    expect(timeline.recentEvents.map((event) => event.name), ['Closed Today']);
  });

  test('treats Laravel UTC ISO datetimes as campus wall-clock time', () {
    final timeline = EventTimeline.fromEvents([
      event(
        id: 1,
        name: 'John Mark Yecyec',
        eventDate: '2026-07-04T16:00:00.000000Z',
        loginDateTime: '2026-07-05T05:49:00.000000Z',
        logoutDateTime: '2026-07-05T08:08:00.000000Z',
      ),
    ], now: DateTime.parse('2026-07-05 13:53:00'));

    expect(timeline.currentEvents.map((event) => event.name), [
      'John Mark Yecyec',
    ]);
    expect(timeline.recentEvents, isEmpty);
  });

  test('campusNow returns a wall-clock DateTime, not a UTC instant', () {
    expect(EventTimeline.campusNow().isUtc, isFalse);
  });
}

EventModel event({
  required int id,
  required String name,
  String? eventDate,
  String? loginDateTime,
  String? logoutDateTime,
  String? attendancePhase,
}) {
  return EventModel(
    id: id,
    name: name,
    eventDate: eventDate,
    loginDateTime: loginDateTime,
    logoutDateTime: logoutDateTime,
    attendancePhase: attendancePhase,
  );
}
