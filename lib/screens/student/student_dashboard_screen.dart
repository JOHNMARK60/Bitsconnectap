import 'dart:math' as math;
import 'dart:async';

import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/utils/date_formatter.dart';
import 'package:bits_mobile_app/core/utils/event_timeline.dart';
import 'package:bits_mobile_app/core/utils/qr_code_file.dart';
import 'package:bits_mobile_app/core/widgets/announcement_content.dart';
import 'package:bits_mobile_app/core/widgets/error_view.dart';
import 'package:bits_mobile_app/core/widgets/loading_view.dart';
import 'package:bits_mobile_app/core/widgets/paginated_event_list.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/models/user_model.dart';
import 'package:bits_mobile_app/screens/student/student_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with WidgetsBindingObserver {
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final student = context.read<StudentController>();
      await student.loadDashboard();
      await student.loadNotifications(showDeviceAlerts: true);
    });
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        context.read<StudentController>().loadNotifications(
          showDeviceAlerts: true,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final student = context.read<StudentController>();
      student.loadDashboard();
      student.loadNotifications(showDeviceAlerts: true);
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentController>();
    final authUser = context.watch<AuthController>().user;
    final dashboard = Map<String, dynamic>.from(student.dashboard ?? {});
    final profile = Map<String, dynamic>.from(
      dashboard['profile'] as Map? ?? {},
    );
    final user = Map<String, dynamic>.from(profile['user'] as Map? ?? {});
    final details = Map<String, dynamic>.from(profile['details'] as Map? ?? {});
    final stats = Map<String, dynamic>.from(dashboard['stats'] as Map? ?? {});
    final recentAttendance = (dashboard['recent_attendance'] as List? ?? [])
        .whereType<Object>()
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final eventTimeline = EventTimeline.fromEvents(
      student.events,
      now: student.eventReferenceTime(),
    );
    final fullName = _firstNonEmpty([
      displayName(user, fallback: ''),
      user['full_name'],
      user['name'],
      user['student_name'],
      authUser?.fullName,
      'Student',
    ]);
    final qrCode = _firstNonEmptyOrNull([
      user['qr_code'],
      student.qrCode,
      authUser?.qrCode,
    ]);

    return StudentChrome(
      currentRoute: AppRoutes.studentDashboard,
      onRefresh: () async {
        await student.loadDashboard();
        await student.loadNotifications(showDeviceAlerts: true);
      },
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
        children: [
          if (student.loading && student.dashboard == null)
            const SizedBox(height: 520, child: LoadingView())
          else if (student.error != null && student.dashboard == null)
            ErrorView(message: student.error!, onRetry: student.loadDashboard)
          else ...[
            const _SectionHeader('Overview'),
            const SizedBox(height: 18),
            _OverviewCard(
              icon: Icons.credit_card_outlined,
              label: 'Attendance',
              title: 'Attended Events',
              value: _stat(stats, 'attended_events', fallback: '0'),
              gradient: const [Color(0xFF13A8FF), Color(0xFF0074E8)],
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.studentAttendedEvents),
            ),
            const SizedBox(height: 16),
            _OverviewCard(
              icon: Icons.calendar_month,
              label: 'Campus',
              title: 'Available Events',
              value: _stat(stats, 'available_events', fallback: '0'),
              gradient: const [Color(0xFFFF7A1A), Color(0xFFFFC107)],
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.studentEvents),
            ),
            const SizedBox(height: 16),
            _OverviewCard(
              icon: Icons.school,
              label: 'Profile',
              title: 'Academic Level',
              value: _firstNonEmpty([details['year'], 'N/A']),
              gradient: const [Color(0xFF05C18B), Color(0xFF00DCA5)],
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.studentProfile),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Secondary'),
            const SizedBox(height: 18),
            _EventTimelinePanel(
              title: 'Available Events',
              events: eventTimeline.currentEvents,
              emptyText: 'No available event today.',
            ),
            const SizedBox(height: 20),
            _EventTimelinePanel(
              title: 'Recent Events',
              events: eventTimeline.recentEvents,
              emptyText: 'No recent event history yet.',
              paginated: true,
            ),
            const SizedBox(height: 20),
            _Panel(
              title: 'Attendance Line Chart',
              child: SizedBox(
                height: 320,
                child: _AttendanceChart(
                  entries: _chartEntries(recentAttendance),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _ActivityPanel(items: recentAttendance),
            const SizedBox(height: 20),
            _AnnouncementsPanel(items: student.announcements),
            const SizedBox(height: 20),
            student.qrEnabled
                ? _QrPanel(
                    qrCode: qrCode,
                    profileComplete: student.profileComplete,
                  )
                : _QrDisabledPanel(message: student.qrDisabledMessage),
            const SizedBox(height: 20),
            _ProfileSummaryPanel(
              user: user,
              details: details,
              fallbackName: fullName,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF141827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, color: Color(0xFF667085), size: 22),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.value,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String title;
  final String value;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        height: 158,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F12263F),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(right: -74, bottom: -92, child: _GhostCircle(168)),
            const Positioned(right: 24, bottom: -68, child: _GhostCircle(104)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0x29FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 17),
                    ),
                    const Spacer(),
                    const Text(
                      'View Detail',
                      style: TextStyle(
                        color: Color(0xEAFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostCircle extends StatelessWidget {
  const _GhostCircle(this.size);

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0x24FFFFFF),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.trailing,
    this.centerTitle = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F12263F),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  textAlign: centerTitle ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(
                    color: Color(0xFF141827),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (!centerTitle)
                const Icon(Icons.more_vert, color: Color(0xFF98A2B3)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart({required this.entries});

  final List<_ChartEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: _EmptyState(text: 'No attendance chart data yet.'),
      );
    }

    return Column(
      children: [
        const Row(
          children: [
            _LegendDot(color: Color(0xFF0D9DFF), text: 'attendance records'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(child: CustomPaint(painter: _ChartPainter(entries))),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter(this.entries);

  final List<_ChartEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const bottom = 46.0;
    const top = 14.0;
    const right = 16.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EEF6)
      ..strokeWidth = 1;
    final baselinePaint = Paint()
      ..color = const Color(0xFFD4E4F6)
      ..strokeWidth = 1.4;
    final axisText = const TextStyle(color: Color(0xFF667085), fontSize: 11);

    for (final tick in const [0.0, .5, 1.0]) {
      final y = chart.bottom - chart.height * tick;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      _paintText(
        canvas,
        tick == 1
            ? '1'
            : tick == 0
            ? '0'
            : '.5',
        Offset(2, y - 7),
        axisText,
      );
    }
    canvas.drawLine(chart.bottomLeft, chart.bottomRight, baselinePaint);

    final points = <Offset>[];
    final lastIndex = math.max(entries.length - 1, 1);

    for (var i = 0; i < entries.length; i++) {
      final x = entries.length == 1
          ? chart.center.dx
          : chart.left + (chart.width * i / lastIndex);
      final y = chart.bottom - (chart.height * entries[i].attendanceValue);
      points.add(Offset(x, y));
      if (_shouldPaintLabel(i, entries.length)) {
        _paintCenteredText(
          canvas,
          entries[i].label,
          Offset(x, chart.bottom + 12),
          axisText,
          maxWidth: 54,
        );
      }
    }

    final linePaint = Paint()
      ..color = const Color(0xFF0D9DFF)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final dotFill = Paint()..color = Colors.white;
    final dotBorder = Paint()
      ..color = const Color(0xFF0D9DFF)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    for (final point in points) {
      canvas.drawCircle(point, 5.5, dotFill);
      canvas.drawCircle(point, 5.5, dotBorder);
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _paintCenteredText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(anchor.dx - painter.width / 2, anchor.dy));
  }

  bool _shouldPaintLabel(int index, int length) {
    if (length <= 4) return true;
    return index == 0 || index == length - 1 || index.isEven;
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'User Activity',
      child: items.isEmpty
          ? const _EmptyState(text: 'No activity yet.')
          : Column(
              children: items
                  .take(4)
                  .map((item) => _ActivityRow(item: item))
                  .toList(),
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final event = Map<String, dynamic>.from(item['event'] as Map? ?? {});
    final title = _firstNonEmpty([event['name'], 'Event activity']);
    final action = item['logout_time'] == null ? 'Logged in' : 'Logged out';
    final time = _firstNonEmpty([item['login_time'], item['updated_at'], '']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const _RoundBadge(text: 'IN'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF141827),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(color: Color(0xFF98A2B3), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EventTimelinePanel extends StatelessWidget {
  const _EventTimelinePanel({
    required this.title,
    required this.events,
    required this.emptyText,
    this.paginated = false,
  });

  final String title;
  final List<EventModel> events;
  final String emptyText;
  final bool paginated;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      trailing: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF667085),
          textStyle: TextStyle(
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.studentEvents),
        child: const Text('View all'),
      ),
      child: events.isEmpty
          ? _EmptyState(text: emptyText)
          : paginated
          ? PaginatedEventList(
              events: events,
              itemBuilder: (event) => _EventRow(event: event),
            )
          : Column(
              children: events.map((event) => _EventRow(event: event)).toList(),
            ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final title = _firstNonEmpty([event.name, 'Campus event']);
    final date = _firstNonEmpty([event.eventDate, event.loginDateTime, '']);
    final meta = _firstNonEmpty([
      _eventSchedule(event),
      [event.academicYear, event.semester]
          .where((value) => value != null && value.toString().trim().isNotEmpty)
          .join(' - '),
      'Event schedule',
    ]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          _DateBadge(date: date),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF141827),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.attendancePhaseDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: event.isAttendancePhaseOpen
                        ? const Color(0xFF16803A)
                        : const Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsPanel extends StatelessWidget {
  const _AnnouncementsPanel({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Announcements',
      trailing: IconButton(
        tooltip: 'Open notifications',
        onPressed: () => _showAnnouncementSheet(context, items),
        icon: const Icon(Icons.notifications_none, color: Color(0xFF98A2B3)),
      ),
      child: items.isEmpty
          ? const _EmptyState(text: 'No announcements at the moment.')
          : Column(
              children: items
                  .take(4)
                  .map((item) => _AnnouncementRow(item: item))
                  .toList(),
            ),
    );
  }
}

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final title = _firstNonEmpty([item['title'], 'Announcement']);
    final date = _firstNonEmpty([item['date'], item['created_at'], '']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showAnnouncementDetails(context, item),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: Color(0xFF0D6EFD),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF141827),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to view full announcement',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: const TextStyle(color: Color(0xFF98A2B3), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrDisabledPanel extends StatelessWidget {
  const _QrDisabledPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Student QR Code',
      centerTitle: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          border: Border.all(color: const Color(0xFFFDE68A)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFB45309)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.qrCode, required this.profileComplete});

  final String? qrCode;
  final bool profileComplete;

  @override
  Widget build(BuildContext context) {
    final hasQr = qrCode != null && qrCode!.trim().isNotEmpty;

    return _Panel(
      title: 'Student QR Code',
      centerTitle: true,
      child: !profileComplete
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFFB45309)),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete your student profile and upload a profile photo before using QR attendance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.studentProfile),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Complete profile'),
                  ),
                ],
              ),
            )
          : hasQr
          ? Column(
              children: [
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showQrCodePreview(context, qrCode!),
                    child: Container(
                      width: 190,
                      height: 190,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5EAF2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: qrCode!,
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(190, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () => _saveQr(context, qrCode!),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download QR Code'),
                ),
              ],
            )
          : const _EmptyState(text: 'QR Code not generated yet.'),
    );
  }

  Future<void> _saveQr(BuildContext context, String value) async {
    try {
      await saveQrCodePng(value, filePrefix: 'bits-student-qr');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code downloaded successfully.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to download QR code. Please check storage permission and try again.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

void _showAnnouncementSheet(
  BuildContext context,
  List<Map<String, dynamic>> items,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const Text(
            'Announcements',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const _EmptyState(text: 'No announcements at the moment.')
          else
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.primary,
                ),
                title: Text(item['title']?.toString() ?? 'Announcement'),
                trailing: Text(item['date']?.toString() ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  _showAnnouncementDetails(context, item);
                },
              ),
        ],
      ),
    ),
  );
}

void _showAnnouncementDetails(BuildContext context, Map<String, dynamic> item) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: .72,
      minChildSize: .45,
      maxChildSize: .92,
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
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']?.toString() ?? 'Announcement',
                          style: const TextStyle(
                            color: Color(0xFF141827),
                            fontSize: 20,
                            height: 1.18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F6FD),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item['date']?.toString() ?? '',
                            style: const TextStyle(
                              color: Color(0xFF335C85),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
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
                child: AnnouncementContent(
                  html: announcementHtmlFromMap(item),
                  fallbackText: announcementTextFromMap(item),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ProfileSummaryPanel extends StatelessWidget {
  const _ProfileSummaryPanel({
    required this.user,
    required this.details,
    required this.fallbackName,
  });

  final Map<String, dynamic> user;
  final Map<String, dynamic> details;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Profile Summary',
      trailing: const SizedBox.shrink(),
      child: Column(
        children: [
          _SummaryRow(
            label: 'ID Number',
            value: _firstNonEmpty([details['idnumber'], 'Not available']),
          ),
          _SummaryRow(
            label: 'Course',
            value: _firstNonEmpty([details['course'], 'No course available']),
          ),
          _SummaryRow(
            label: 'Full Name',
            value: _firstNonEmpty([user['full_name'], fallbackName]),
          ),
          _SummaryRow(
            label: 'Email',
            value: _firstNonEmpty([user['email'], 'Not available']),
          ),
          _SummaryRow(
            label: 'Academic Year',
            value: _firstNonEmpty([details['academic_year'], 'Unknown']),
          ),
          _SummaryRow(
            label: 'Semester',
            value: _firstNonEmpty([details['semester'], 'Unknown']),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD8E1EF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  const _RoundBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF7FF),
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0D6EFD),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(date);
    final day = parsed == null ? '--' : parsed.day.toString().padLeft(2, '0');
    final month = parsed == null
        ? '--'
        : const [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ][parsed.month - 1];

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: Color(0xFF0D6EFD),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            month,
            style: const TextStyle(
              color: Color(0xFF0D6EFD),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 13, top: 2),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEF2F7))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF141827),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _stat(
  Map<String, dynamic> stats,
  String key, {
  required String fallback,
}) {
  final value = stats[key]?.toString().trim();
  if (value == null || value.isEmpty || value == 'null') return fallback;
  return value;
}

class _ChartEntry {
  const _ChartEntry({required this.label, required this.attendanceValue});

  final String label;
  final double attendanceValue;
}

List<_ChartEntry> _chartEntries(List<Map<String, dynamic>> recentAttendance) {
  final records = recentAttendance
      .where(
        (item) =>
            _firstNonEmpty([item['login_time'], item['scanned_at']]).isNotEmpty,
      )
      .take(7)
      .toList()
      .reversed;

  return records.map((item) {
    final event = Map<String, dynamic>.from(item['event'] as Map? ?? {});
    final labelSource = _firstNonEmpty([
      event['event_date'],
      item['login_time'],
      item['scanned_at'],
    ]);

    return _ChartEntry(
      label: _shortChartLabel(labelSource),
      attendanceValue: 1,
    );
  }).toList();
}

String _shortChartLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.length > 6 ? value.substring(0, 6) : value;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[parsed.month - 1]} ${parsed.day}';
}

String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

String? _firstNonEmptyOrNull(List<Object?> values) {
  final value = _firstNonEmpty(values);
  return value.isEmpty ? null : value;
}

String _eventSchedule(EventModel event) {
  final startDateTime = _firstNonEmpty([
    event.loginDateTime,
    event.attendanceStartTime,
  ]);
  if (startDateTime.isNotEmpty) return DateFormatter.dateTime(startDateTime);

  final date = _firstNonEmpty([event.eventDate]);
  if (date.isNotEmpty) return DateFormatter.date(date);

  return '';
}
