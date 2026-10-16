import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/scanner_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/utils/date_formatter.dart';
import 'package:bits_mobile_app/core/utils/event_timeline.dart';
import 'package:bits_mobile_app/core/widgets/brand_logo.dart';
import 'package:bits_mobile_app/models/attended_event_model.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/screens/scanner/widgets/scanner_logout_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScannerDashboardScreen extends StatefulWidget {
  const ScannerDashboardScreen({super.key});

  @override
  State<ScannerDashboardScreen> createState() => _ScannerDashboardScreenState();
}

class _ScannerDashboardScreenState extends State<ScannerDashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scanner = context.read<ScannerController>();
      scanner.loadDashboard();
      scanner.loadHistory();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final scanner = context.read<ScannerController>();
      scanner.loadDashboard();
      scanner.loadHistory();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerController>();
    final user = context.watch<AuthController>().user;
    final stats = Map<String, dynamic>.from(
      scanner.dashboard?['stats'] as Map? ?? {},
    );
    final name = user?.fullName ?? 'Scanner User';
    final recentScans = scanner.history;
    final eventTimeline = EventTimeline.fromEvents(
      scanner.events,
      now: scanner.eventReferenceTime(),
    );
    final scannerDisabledMessage = scanner.scannerPolicyMessage(null);
    final qrDisabledMessage = scanner.qrEnabled
        ? null
        : scanner.qrDisabledMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ScannerDrawer(),
      appBar: _ScannerTopBar(name: name),
      bottomNavigationBar: const _ScannerBottomNav(
        currentRoute: AppRoutes.scannerDashboard,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: scannerDisabledMessage == null
            ? () =>
                  Navigator.pushNamed(context, AppRoutes.scannerFaceAttendance)
            : () => _showPolicyMessage(context, scannerDisabledMessage),
        child: const Icon(Icons.face_retouching_natural, size: 30),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await scanner.loadDashboard();
          await scanner.loadHistory();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            Text(
              'Hello, $name',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 21,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome back to your Scanner Dashboard.',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 30),
            if (scanner.loading && scanner.dashboard == null)
              const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (scanner.error != null && scanner.dashboard == null)
              _StateCard(
                message: scanner.error!,
                onRetry: scanner.loadDashboard,
              )
            else ...[
              _HeroMetricCard(
                icon: Icons.face_retouching_natural,
                badge: 'Live',
                value: _stat(stats, 'total_scans'),
                label: 'TOTAL SCANS',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.today_outlined,
                      iconColor: const Color(0xFF007A80),
                      iconBackground: const Color(0xFFDDFBFF),
                      value: _stat(stats, 'scans_today'),
                      label: 'SCANS\nTODAY',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.event_available_outlined,
                      iconColor: const Color(0xFF344054),
                      iconBackground: const Color(0xFFF1F4FF),
                      value: _stat(stats, 'events'),
                      label: 'EVENTS\nMANAGED',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 42),
            if (scannerDisabledMessage != null ||
                qrDisabledMessage != null) ...[
              _PolicyStatusCard(
                message: scannerDisabledMessage ?? qrDisabledMessage!,
              ),
              const SizedBox(height: 24),
            ],
            _EventTimelineSection(
              title: 'Available Events',
              events: eventTimeline.currentEvents,
              emptyText: 'No available event today.',
            ),
            const SizedBox(height: 34),
            _EventTimelineSection(
              title: 'Recent Events',
              events: eventTimeline.recentEvents,
              emptyText: 'No recent event history yet.',
            ),
            const SizedBox(height: 34),
            const _SectionTitle('Scan Options'),
            const SizedBox(height: 20),
            _ScanOptions(scanner: scanner),
            const SizedBox(height: 34),
            const _SectionTitle('Quick Actions'),
            const SizedBox(height: 20),
            const _QuickActions(),
            const SizedBox(height: 38),
            _SpotlightCard(
              onTap: scannerDisabledMessage == null
                  ? () => Navigator.pushNamed(
                      context,
                      AppRoutes.scannerFaceAttendance,
                    )
                  : () => _showPolicyMessage(context, scannerDisabledMessage),
            ),
            const SizedBox(height: 42),
            const _SectionTitle('Recent Scan Activity'),
            const SizedBox(height: 20),
            if (recentScans.isEmpty)
              const _DashboardCard(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No recent scan activity yet.',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...recentScans
                  .take(2)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecentScanCard(item: item),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ScannerTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ScannerTopBar({required this.name});

  final String name;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFFF8F9FF),
      foregroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          const BrandLogo(size: 34),
          const SizedBox(width: 8),
          const Text(
            'BITSConnect',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none, size: 30),
        ),
        const ScannerLogoutButton(),
        Builder(
          builder: (context) => IconButton(
            tooltip: 'Scanner menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu, size: 26),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5EAF3)),
      ),
    );
  }
}

class ScannerDrawer extends StatelessWidget {
  const ScannerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = ModalRoute.of(context)?.settings.name;
    final items = [
      (AppRoutes.scannerDashboard, 'Dashboard', Icons.home_outlined),
      (AppRoutes.scannerEvents, 'Events', Icons.event_outlined),
      (AppRoutes.scannerHistory, 'Records', Icons.description_outlined),
      (AppRoutes.scannerQr, 'QR Scanner', Icons.qr_code_scanner),
      (
        AppRoutes.scannerFaceAttendance,
        'Face Attendance',
        Icons.face_retouching_natural,
      ),
      (
        AppRoutes.scannerFaceRegistration,
        'Face Registration',
        Icons.person_add_alt_1,
      ),
    ];
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              accountName: Text('Scanner Portal'),
              accountEmail: Text('Attendance operations'),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.qr_code_scanner),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in items)
                    ListTile(
                      selected: selected == item.$1,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: .1,
                      ),
                      leading: Icon(
                        item.$3,
                        color: selected == item.$1 ? AppColors.primary : null,
                      ),
                      title: Text(item.$2),
                      onTap: selected == item.$1
                          ? null
                          : () {
                              Navigator.pop(context);
                              Navigator.pushReplacementNamed(context, item.$1);
                            },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            const ScannerLogoutButton(),
          ],
        ),
      ),
    );
  }
}

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({
    required this.icon,
    required this.badge,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String badge;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(
                icon: icon,
                color: AppColors.primary,
                background: const Color(0xFFEAF2FF),
              ),
              const Spacer(),
              _Badge(label: badge),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      minHeight: 198,
      padding: const EdgeInsets.fromLTRB(30, 30, 24, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon, color: iconColor, background: iconBackground),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOptions extends StatelessWidget {
  const _ScanOptions({required this.scanner});

  final ScannerController scanner;

  @override
  Widget build(BuildContext context) {
    final scannerDisabledMessage = scanner.scannerPolicyMessage(null);

    return Column(
      children: [
        _ScanOptionCard(
          title: 'Face Recognition',
          subtitle: 'Capture a student face and record event attendance.',
          icon: Icons.face_retouching_natural,
          route: AppRoutes.scannerFaceAttendance,
          accent: AppColors.teal,
          disabledMessage: scannerDisabledMessage,
        ),
        if (scanner.qrEnabled) ...[
          const SizedBox(height: 14),
          _ScanOptionCard(
            title: 'QR Fallback',
            subtitle: 'Use QR only when face attendance needs a fallback.',
            icon: Icons.qr_code_scanner_outlined,
            route: AppRoutes.scannerQr,
            accent: AppColors.primary,
            disabledMessage: scannerDisabledMessage,
          ),
        ],
        const SizedBox(height: 14),
        const _ScanOptionCard(
          title: 'Register Student Face',
          subtitle: 'Select a student and enroll their face securely.',
          icon: Icons.person_add_alt_1_outlined,
          route: AppRoutes.scannerFaceRegistration,
          accent: AppColors.primary,
        ),
      ],
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  const _ScanOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.accent,
    this.disabledMessage,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color accent;
  final String? disabledMessage;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => disabledMessage == null
            ? Navigator.pushNamed(context, route)
            : _showPolicyMessage(context, disabledMessage!),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB9C2D3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: disabledMessage == null ? .12 : .06,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: disabledMessage == null ? accent : AppColors.muted,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: disabledMessage == null
                            ? AppColors.text
                            : AppColors.muted,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                disabledMessage == null
                    ? Icons.chevron_right
                    : Icons.lock_outline,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      children: const [
        _ActionButton(
          label: 'Scan\nHistory',
          icon: Icons.manage_search_outlined,
          route: AppRoutes.scannerHistory,
        ),
        _ActionButton(
          label: 'Face\nScan',
          icon: Icons.face_retouching_natural,
          route: AppRoutes.scannerFaceAttendance,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB9C2D3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 27),
              const SizedBox(width: 22),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
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

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -8,
            bottom: -28,
            child: Icon(
              Icons.face_retouching_natural,
              color: Color(0x1FFFFFFF),
              size: 138,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SCANNER SPOTLIGHT',
                style: TextStyle(
                  color: Color(0xFFADC6FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Face Recognition Check-in',
                style: TextStyle(
                  color: Color(0xFFD3DFFF),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Capture a student face and record attendance in real time.',
                style: TextStyle(
                  color: Color(0xFFD3DFFF),
                  fontSize: 17,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF87F3FF),
                  foregroundColor: const Color(0xFF001F23),
                  minimumSize: const Size(178, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: onTap,
                child: const Text('Start Scanning'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventTimelineSection extends StatelessWidget {
  const _EventTimelineSection({
    required this.title,
    required this.events,
    required this.emptyText,
  });

  final String title;
  final List<EventModel> events;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 20),
        if (events.isEmpty)
          _DashboardCard(
            padding: const EdgeInsets.all(24),
            child: Text(
              emptyText,
              style: const TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DashboardEventCard(event: event),
            ),
          ),
      ],
    );
  }
}

class _DashboardEventCard extends StatelessWidget {
  const _DashboardEventCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final status = event.attendanceStatus?.trim();

    return _DashboardCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (status != null && status.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _MiniStatus(label: status),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _eventSchedule(event),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _eventMeta(event),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDDFBFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF007A80),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  const _RecentScanCard({required this.item});

  final AttendedEventModel item;

  @override
  Widget build(BuildContext context) {
    final name = item.studentName?.trim().isNotEmpty == true
        ? item.studentName!
        : 'Student Record';
    final eventName = item.event?.name ?? 'Campus Event Check-in';

    return _DashboardCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFDDFBFF),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Color(0xFF006971),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  eventName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View history',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.scannerHistory),
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primary,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    required this.padding,
    this.minHeight,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: .9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 54,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDDFBFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4CD9E7),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.primary, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _PolicyStatusCard extends StatelessWidget {
  const _PolicyStatusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerBottomNav extends StatelessWidget {
  const _ScannerBottomNav({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFC2C6D5))),
          boxShadow: [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomNavItem(
              'Home',
              Icons.home_outlined,
              AppRoutes.scannerDashboard,
              selected: currentRoute == AppRoutes.scannerDashboard,
            ),
            _BottomNavItem(
              'Events',
              Icons.calendar_month_outlined,
              AppRoutes.scannerEvents,
              selected: currentRoute == AppRoutes.scannerEvents,
            ),
            _BottomNavItem(
              'Records',
              Icons.description_outlined,
              AppRoutes.scannerHistory,
              selected: currentRoute == AppRoutes.scannerHistory,
            ),
            _BottomNavItem(
              'Scan',
              Icons.face_retouching_natural,
              AppRoutes.scannerFaceAttendance,
              selected: currentRoute == AppRoutes.scannerFaceAttendance,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem(
    this.label,
    this.icon,
    this.route, {
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 27),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
          ),
        ),
      ],
    );

    if (selected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(13),
        ),
        child: IconTheme(
          data: const IconThemeData(color: Colors.white),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: content,
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(context, route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: IconTheme(
          data: const IconThemeData(color: AppColors.text),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: AppColors.text),
            child: content,
          ),
        ),
      ),
    );
  }
}

String _stat(Map<String, dynamic> stats, String key) {
  final value = stats[key]?.toString().trim();
  if (value == null || value.isEmpty || value == 'null') return '0';
  return value;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'B';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

String _eventSchedule(EventModel event) {
  final startDateTime = _firstNonEmpty([
    event.loginDateTime,
    event.attendanceStartTime,
  ]);
  if (startDateTime.isNotEmpty) return DateFormatter.dateTime(startDateTime);

  final date = _firstNonEmpty([event.eventDate]);
  if (date.isNotEmpty) return DateFormatter.date(date);

  return 'Schedule not set';
}

String _eventMeta(EventModel event) {
  final values = [
    event.academicYear,
    event.semester,
  ].where((value) => value != null && value.trim().isNotEmpty).join(' - ');

  return values.isEmpty ? 'Event schedule' : values;
}

String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

void _showPolicyMessage(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Scanner Disabled'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
