import 'package:bits_mobile_app/core/widgets/paginated_event_list.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/models/attended_event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<EventModel> events(int count) => List.generate(
  count,
  (index) => EventModel(id: index + 1, name: 'Event ${index + 1}'),
);

Widget subject(List<EventModel> items) => MaterialApp(
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(36),
      child: PaginatedEventList(
        events: items,
        itemBuilder: (event) => Text(event.name),
      ),
    ),
  ),
);

void main() {
  testWidgets('attended events show one record per page, newest first', (
    tester,
  ) async {
    final items = [
      const AttendedEventModel(id: 1, loginTime: '2026-09-01 09:00:00'),
      const AttendedEventModel(id: 3, loginTime: '2026-10-08 09:00:00'),
      const AttendedEventModel(id: 2, scannedTime: '2026-10-01 09:00:00'),
      const AttendedEventModel(id: 4),
    ]..sort(AttendedEventModel.compareNewestFirst);
    expect(items.map((item) => item.id), [3, 2, 1, 4]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginatedList<AttendedEventModel>(
            items: items,
            itemId: (item) => item.id,
            pageSize: 1,
            itemBuilder: (item) => Text('Attendance ${item.id}'),
          ),
        ),
      ),
    );
    expect(find.text('Attendance 3'), findsOneWidget);
    expect(find.text('Attendance 2'), findsNothing);
    expect(find.text('Showing 1–1 of 4 events'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(find.text('Attendance 3'), findsNothing);
    expect(find.text('Attendance 2'), findsOneWidget);
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(find.text('Attendance 4'), findsOneWidget);
    expect(find.text('Showing 4–4 of 4 events'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('attendance sorting falls back to schedule and breaks ties by ID', () {
    final items = [
      const AttendedEventModel(id: 1),
      const AttendedEventModel(id: 2),
      const AttendedEventModel(
        id: 3,
        loginTime: 'invalid',
        event: EventModel(id: 3, name: 'Event', eventDate: '2026-10-01'),
      ),
      const AttendedEventModel(id: 4, loginTime: '2026-10-08 09:00:00'),
      const AttendedEventModel(id: 5, loginTime: '2026-10-08 09:00:00'),
    ]..sort(AttendedEventModel.compareNewestFirst);
    expect(items.map((item) => item.id), [5, 4, 3, 2, 1]);
  });

  testWidgets('shows five events and navigates to the partial last page', (
    tester,
  ) async {
    await tester.pumpWidget(subject(events(12)));
    expect(find.text('Event 1'), findsOneWidget);
    expect(find.text('Event 5'), findsOneWidget);
    expect(find.text('Event 6'), findsNothing);
    expect(find.text('Showing 1–5 of 12 events'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(find.text('Event 1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(find.text('Event 1'), findsNothing);
    expect(find.text('Event 6'), findsOneWidget);
    expect(find.text('Event 10'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('Showing 11–12 of 12 events'), findsOneWidget);
    expect(find.text('Event 11'), findsOneWidget);
    expect(find.text('Event 12'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(find.text('Event 11'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(find.text('Event 6'), findsOneWidget);
  });

  testWidgets('keeps the page on rebuild and resets when events change', (
    tester,
  ) async {
    await tester.pumpWidget(subject(events(12)));
    await tester.tap(find.text('3'));
    await tester.pumpWidget(subject(events(12)));
    expect(find.text('Event 11'), findsOneWidget);
    await tester.pumpWidget(subject(events(3)));
    expect(find.text('Showing 1–3 of 3 events'), findsOneWidget);
    await tester.pumpWidget(subject([]));
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large page counts fit a small phone and can reach the last page',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(subject(events(60)));
      expect(find.text('…'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('12'));
      await tester.pump();
      expect(find.text('Showing 56–60 of 60 events'), findsOneWidget);
      await tester.tap(find.text('1'));
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pump();
      }
      expect(find.text('Showing 26–30 of 60 events'), findsOneWidget);
      expect(find.text('…'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
