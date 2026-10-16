import 'dart:convert';

import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/controllers/theme_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/widgets/announcement_content.dart';
import 'package:bits_mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:bits_mobile_app/core/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentChrome extends StatelessWidget {
  const StudentChrome({
    required this.currentRoute,
    required this.body,
    this.onRefresh,
    super.key,
  });

  final String currentRoute;
  final Widget body;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const StudentDrawer(),
      appBar: const StudentTopBar(),
      bottomNavigationBar: StudentBottomNav(currentRoute: currentRoute),
      body: onRefresh == null
          ? body
          : RefreshIndicator(onRefresh: onRefresh!, child: body),
    );
  }
}

class StudentTopBar extends StatelessWidget implements PreferredSizeWidget {
  const StudentTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final profile = context.watch<StudentController>().profile;
    final details = Map<String, dynamic>.from(
      (profile?['details'] as Map?) ?? {},
    );

    return AppBar(
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF111827)
          : Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          const BrandLogo(size: 34),
          const SizedBox(width: 8),
          Text(
            'BITSConnect',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        _HeaderButton(
          icon: Icons.notifications_none,
          tooltip: 'Notifications',
          badge: context.watch<StudentController>().unreadNotifications > 0,
          onTap: () => _showNotifications(context),
        ),
        const SizedBox(width: 16),
        _HeaderButton(
          icon: context.watch<ThemeController>().darkMode
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          tooltip: 'Toggle dark mode',
          onTap: () => context.read<ThemeController>().toggle(),
        ),
        const SizedBox(width: 18),
        StudentAvatar(
          name: user?.fullName ?? 'Student',
          photo: details['photo']?.toString(),
          size: 44,
        ),
        const SizedBox(width: 16),
        _HeaderButton(
          icon: Icons.menu,
          tooltip: 'Student menu',
          onTap: () => Scaffold.of(context).openDrawer(),
        ),
        const SizedBox(width: 12),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }
}

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final selected = ModalRoute.of(context)?.settings.name;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              accountName: Text(user?.fullName ?? 'Student'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.school_outlined),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(
                    context,
                    'Dashboard',
                    Icons.home_outlined,
                    AppRoutes.studentDashboard,
                    selected,
                  ),
                  _drawerItem(
                    context,
                    'Events',
                    Icons.calendar_month_outlined,
                    AppRoutes.studentEvents,
                    selected,
                  ),
                  _drawerItem(
                    context,
                    'Face Attendance',
                    Icons.verified_user_outlined,
                    AppRoutes.studentFaceAttendance,
                    selected,
                  ),
                  _drawerItem(
                    context,
                    'Profile',
                    Icons.person_outline,
                    AppRoutes.studentProfile,
                    selected,
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'ACCOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  _drawerItem(
                    context,
                    'Face Registration',
                    Icons.face_retouching_natural,
                    AppRoutes.studentFaceRegistration,
                    selected,
                  ),
                  _drawerItem(
                    context,
                    'Change Password',
                    Icons.lock_reset,
                    AppRoutes.studentChangePassword,
                    selected,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                final ok = await showConfirmationDialog(
                  context,
                  'Logout',
                  'Do you want to sign out?',
                );
                if (!ok || !context.mounted) return;
                await context.read<AuthController>().logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    String label,
    IconData icon,
    String route,
    String? selected,
  ) {
    final active = selected == route;
    return ListTile(
      selected: active,
      selectedTileColor: AppColors.primary.withValues(alpha: .1),
      leading: Icon(icon, color: active ? AppColors.primary : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      onTap: active
          ? null
          : () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, route);
            },
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F2937)
                : const Color(0xFFF0F6FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              if (badge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    required this.name,
    this.photo,
    this.size = 56,
    super.key,
  });

  final String name;
  final String? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = _imageProvider(photo);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFD8FF), width: 4),
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFF213145),
        backgroundImage: image,
        child: image == null
            ? Text(
                _initials(name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * .22,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}

class StudentBottomNav extends StatelessWidget {
  const StudentBottomNav({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    const items = [
      (AppRoutes.studentDashboard, Icons.home_outlined, 'Dashboard'),
      (AppRoutes.studentEvents, Icons.calendar_month_outlined, 'Events'),
      (AppRoutes.studentFaceAttendance, Icons.verified_user_outlined, 'Scan'),
      (AppRoutes.studentProfile, Icons.person_outline, 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF111827)
              : Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final item in items)
              Tooltip(
                message: item.$3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: currentRoute == item.$1
                      ? null
                      : () => Navigator.pushReplacementNamed(context, item.$1),
                  child: Container(
                    width: 54,
                    height: 52,
                    decoration: BoxDecoration(
                      color: currentRoute == item.$1
                          ? AppColors.royal
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.$2,
                          size: 22,
                          color: currentRoute == item.$1
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: currentRoute == item.$1
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showNotifications(BuildContext context) async {
  final controller = context.read<StudentController>();
  await controller.loadNotifications();
  if (!context.mounted) return;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final items = context.watch<StudentController>().notifications;
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await controller.markAllNotificationsRead();
                  },
                  child: const Text('Mark all read'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const _EmptyNotice()
            else
              ..._notificationRows(context, sheetContext, controller, items),
          ],
        ),
      );
    },
  );
}

List<Widget> _notificationRows(
  BuildContext context,
  BuildContext sheetContext,
  StudentController controller,
  List<Map<String, dynamic>> items,
) {
  final rows = <Widget>[];
  String? lastGroup;
  final sortedItems = [...items]
    ..sort((a, b) => _notificationGroup(a).compareTo(_notificationGroup(b)));

  for (final item in sortedItems) {
    final group = _notificationGroup(item);
    if (group != lastGroup) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 14, bottom: 6),
          child: Text(
            group,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ),
      );
      lastGroup = group;
    }

    rows.add(
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          item['read'] == true
              ? Icons.notifications_none
              : Icons.notifications_active,
          color: item['read'] == true ? AppColors.muted : AppColors.primary,
        ),
        title: Text(item['title']?.toString() ?? 'Announcement'),
        subtitle: Text(item['message']?.toString() ?? ''),
        trailing: Text(item['date']?.toString() ?? ''),
        onTap: () async {
          final id = item['id']?.toString();
          if (id != null) await controller.markNotificationRead(id);
          if (!sheetContext.mounted || !context.mounted) return;
          Navigator.pop(sheetContext);
          if (_opensAttendanceRecords(item)) {
            Navigator.pushNamed(context, AppRoutes.studentAttendedEvents);
          } else {
            _showNotificationDetails(context, item);
          }
        },
      ),
    );
  }

  return rows;
}

String _notificationGroup(Map<String, dynamic> item) {
  final type = item['type']?.toString() ?? '';
  if (type == 'attendance_penalty') return 'PENALTIES';
  if (type.startsWith('attendance_')) return 'ATTENDANCE';
  if (type == 'announcement') return 'ANNOUNCEMENTS';
  return 'EVENTS';
}

bool _opensAttendanceRecords(Map<String, dynamic> item) {
  final type = item['type']?.toString() ?? '';
  return type.startsWith('attendance_');
}

void _showNotificationDetails(BuildContext context, Map<String, dynamic> item) {
  final isAnnouncement = item['type']?.toString() == 'announcement';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: .68,
      minChildSize: .4,
      maxChildSize: .9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E1EF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (item['event_name'] != null) ...[
                Text(
                  'Event: ${item['event_name']}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
              ],
              if (item['attendance_status'] != null) ...[
                Text('Status: ${item['attendance_status']}'),
                const SizedBox(height: 8),
              ],
              if (item['recorded_at'] != null) ...[
                Text('Recorded: ${item['recorded_at']}'),
                const SizedBox(height: 8),
              ],
              if (item['reason'] != null) ...[
                Text('Reason: ${item['reason']}'),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isAnnouncement
                          ? Icons.campaign_outlined
                          : Icons.event_available_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']?.toString() ?? 'Notification',
                          style: const TextStyle(
                            color: Color(0xFF141827),
                            fontSize: 20,
                            height: 1.18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['date']?.toString() ?? '',
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFCFE),
                  border: Border.all(color: const Color(0xFFE5EAF2)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isAnnouncement
                    ? AnnouncementContent(
                        html: announcementHtmlFromMap(item),
                        fallbackText: announcementTextFromMap(item),
                      )
                    : Text(
                        item['message']?.toString() ?? '',
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'No notifications yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted),
      ),
    );
  }
}

ImageProvider? _imageProvider(String? source) {
  final value = source?.trim();
  if (value == null || value.isEmpty || value == 'null') return null;
  if (value.startsWith('http')) return NetworkImage(value);
  try {
    final normalized = value.contains(',') ? value.split(',').last : value;
    return MemoryImage(base64Decode(normalized));
  } catch (_) {
    return null;
  }
}

String initialsFor(String name) => _initials(name);

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'SU';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
