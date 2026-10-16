import 'dart:io';
import 'dart:ui' as ui;

import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/controllers/theme_controller.dart';
import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/core/services/auth_service.dart';
import 'package:bits_mobile_app/core/services/mobile_notification_service.dart';
import 'package:bits_mobile_app/core/services/secure_storage_service.dart';
import 'package:bits_mobile_app/core/widgets/paginated_event_list.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/screens/student/student_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _StudentFixture extends StudentController {
  _StudentFixture(ApiService api, SecureStorageService storage)
    : super(api, MobileNotificationService(), storage) {
    dashboard = {};
    events = List.generate(60, (index) {
      final date = DateTime(2026, 9, 30).subtract(Duration(days: index));
      const names = [
        'Sept. 30 Weekly Cleanup',
        'Special Assembly Meeting',
        'Weekly Campus Cleanup',
        'Student Organization Meeting',
        'Community Cleanup Drive',
      ];
      return EventModel(
        id: index + 1,
        name: index < names.length ? names[index] : 'Campus Event ${index + 1}',
        eventDate: date.toIso8601String(),
        loginDateTime: date
            .add(const Duration(hours: 14, minutes: 45))
            .toIso8601String(),
      );
    }).reversed.toList();
  }

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> loadNotifications({bool showDeviceAlerts = false}) async {}

  @override
  DateTime eventReferenceTime() => DateTime(2026, 10, 9);
}

void main() {
  testWidgets(
    'dashboard shows the latest five events with working pagination',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final capture = Platform.environment['CAPTURE_PAGINATION_UI'] == '1';
      if (capture) {
        await tester.runAsync(() async {
          final loader = FontLoader('PreviewFont')
            ..addFont(
              File(
                'C:/Windows/Fonts/segoeui.ttf',
              ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
            );
          await loader.load();
          for (final family in ['Ahem', 'Roboto']) {
            final fallback = FontLoader(family)
              ..addFont(
                File(
                  'C:/Windows/Fonts/segoeui.ttf',
                ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
              );
            await fallback.load();
          }
          final icons = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await icons.load();
        });
      }
      final storage = SecureStorageService();
      final api = ApiService(storage);
      const boundaryKey = ValueKey('dashboard-preview');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<StudentController>(
              create: (_) => _StudentFixture(api, storage),
            ),
            ChangeNotifierProvider(
              create: (_) => AuthController(AuthService(api, storage)),
            ),
            ChangeNotifierProvider(create: (_) => ThemeController(storage)),
          ],
          child: MaterialApp(
            theme: ThemeData(
              fontFamily: capture ? 'PreviewFont' : null,
              scaffoldBackgroundColor: const Color(0xFFF4F6FC),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0D6EFD),
              ),
            ),
            home: const RepaintBoundary(
              key: boundaryKey,
              child: StudentDashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (capture) {
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/images/bits_logo.jpg'),
            tester.element(find.byType(StudentDashboardScreen)),
          ),
        );
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(find.text('Recent Events'), 250);
      await tester.pumpAndSettle();
      final list = find.byType(PaginatedEventList);
      expect(
        find.descendant(
          of: list,
          matching: find.text('Sept. 30 Weekly Cleanup'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: list,
          matching: find.text('Community Cleanup Drive'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: list, matching: find.text('Campus Event 6')),
        findsNothing,
      );
      expect(find.text('Showing 1–5 of 60 events'), findsOneWidget);
      expect(tester.takeException(), isNull);

      if (capture) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('artifacts').create(recursive: true);
          await File(
            'artifacts/recent-events-pagination.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.tap(find.descendant(of: list, matching: find.text('2')));
      await tester.pumpAndSettle();
      expect(find.text('Showing 6–10 of 60 events'), findsOneWidget);
      expect(find.text('Campus Event 6'), findsOneWidget);
      expect(find.text('Sept. 30 Weekly Cleanup'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
