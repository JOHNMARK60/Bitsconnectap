import 'dart:convert';

import 'package:bits_mobile_app/app/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MobileNotificationService {
  static const _seenNotificationIdsKey = 'seen_event_notification_ids';
  static const _channelId = 'campushub_notifications';
  static const _channelName = 'BITSConnect Notifications';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload ?? '';
        final data = _notificationPayload(payload);
        final type = data['type']?.toString();
        final route =
            type != null &&
                (type.startsWith('attendance_') || type == 'penalty')
            ? AppRoutes.studentAttendedEvents
            : AppRoutes.studentDashboard;
        AppNavigator.key.currentState?.pushNamed(route);
      },
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showNewEventNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final campusNotifications = notifications
        .where(
          (item) => const [
            'event',
            'announcement',
            'attendance_time_in',
            'attendance_time_out',
            'attendance_voided',
            'attendance_penalty',
          ].contains(item['type']),
        )
        .toList();
    if (campusNotifications.isEmpty) return;

    final stored = await _storage.read(key: _seenNotificationIdsKey);
    final seen = <String>{
      ...((stored == null ? const <dynamic>[] : jsonDecode(stored) as List).map(
        (id) => id.toString(),
      )),
    };
    final now = DateTime.now();

    for (final item in campusNotifications.reversed) {
      final id = item['id']?.toString();
      if (id == null || seen.contains(id)) continue;

      final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');
      final isRecent =
          createdAt != null &&
          now.difference(createdAt.toLocal()).abs() <=
              const Duration(minutes: 10);

      // On the first run, establish a baseline without replaying old events.
      if (stored != null || isRecent) {
        final isAnnouncement = item['type'] == 'announcement';
        await _notifications.show(
          id: _notificationId(id),
          title:
              item['title']?.toString() ??
              (isAnnouncement ? 'New Announcement' : 'New Campus Event'),
          body: isAnnouncement
              ? null
              : item['message']?.toString() ??
                    'A new event is now available in BITSConnect.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription:
                    'New announcements and events from BITSConnect administrators',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode({'id': id, 'type': item['type']}),
        );
      }
      seen.add(id);
    }

    await _storage.write(
      key: _seenNotificationIdsKey,
      value: jsonEncode(seen.toList()),
    );
  }

  int _notificationId(String value) => value.hashCode & 0x7fffffff;
}

Map<String, dynamic> _notificationPayload(String payload) {
  if (payload.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(payload);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
  } catch (_) {
    return const {};
  }
}
