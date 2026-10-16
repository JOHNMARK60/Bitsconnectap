import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/scanner_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/widgets/brand_logo.dart';
import 'package:bits_mobile_app/models/attended_event_model.dart';
import 'package:bits_mobile_app/screens/scanner/widgets/scanner_logout_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ScannerController>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerController>();
    final records = scanner.history.map(_ScanRecord.fromModel).toList();
    final visibleRecords = _filter(records);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const _HistoryTopBar(),
      bottomNavigationBar: const _ScannerBottomNav(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.scannerFaceAttendance),
        child: const Icon(Icons.face_retouching_natural, size: 32),
      ),
      body: RefreshIndicator(
        onRefresh: scanner.loadHistory,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          children: [
            const Text(
              'Scan History',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Review and manage student attendance\nrecords across all campus events.',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 24,
                height: 1.36,
              ),
            ),
            const SizedBox(height: 36),
            _SearchToolbar(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onFilter: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filters are coming soon.')),
                );
              },
            ),
            const SizedBox(height: 24),
            if (scanner.loading)
              const SizedBox(
                height: 360,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (scanner.error != null)
              _StateCard(message: scanner.error!, onRetry: scanner.loadHistory)
            else if (visibleRecords.isEmpty)
              const _StateCard(message: 'No matching scan history records.')
            else
              ...visibleRecords.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _ScanHistoryCard(record: record),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_ScanRecord> _filter(List<_ScanRecord> records) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return records;

    return records.where((record) {
      final searchable =
          '${record.studentName} ${record.studentId} ${record.eventName} '
                  '${record.attendanceMethod} ${record.fallbackReason} ${record.voidReason}'
              .toLowerCase();
      return searchable.contains(query);
    }).toList();
  }
}

class _HistoryTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _HistoryTopBar();

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFFF8F9FF),
      foregroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 24,
      title: Row(
        children: [
          const BrandLogo(size: 48),
          const SizedBox(width: 20),
          const Text(
            'BITSConnect',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
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
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5EAF3)),
      ),
    );
  }
}

class _SearchToolbar extends StatelessWidget {
  const _SearchToolbar({
    required this.controller,
    required this.onChanged,
    required this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 23),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search by name, ID or event...',
              hintStyle: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 23,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Icon(Icons.search, color: Color(0xFF1F2937), size: 32),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 58),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 21,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFB9C2D3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onFilter,
            child: Container(
              width: 73,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB9C2D3)),
              ),
              child: const Icon(
                Icons.filter_list,
                color: AppColors.text,
                size: 34,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanHistoryCard extends StatelessWidget {
  const _ScanHistoryCard({required this.record});

  final _ScanRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9C2D3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EEFF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          record.studentName,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                        _ActionBadge(label: record.action),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ID: ${record.studentId} | ${record.courseSection} | ${record.eventName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 23,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.assignment_turned_in_outlined,
                          label: record.attendanceMethod,
                        ),
                        if (record.fallbackReason != null)
                          _InfoChip(
                            icon: Icons.qr_code_2,
                            label: record.fallbackReason!,
                          ),
                        if (record.voidReason != null)
                          _InfoChip(
                            icon: Icons.block_outlined,
                            label: record.voidReason!,
                          ),
                      ],
                    ),
                    if (record.voidedAt != null ||
                        record.voidedByName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (record.voidedAt != null)
                            'Voided: ${record.voidedAt}',
                          if (record.voidedByName != null)
                            'By: ${record.voidedByName}',
                        ].join(' | '),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFDDE3EC)),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.primaryTime,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.secondaryDate,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: record.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final login = label.toLowerCase() == 'login';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: login ? const Color(0xFFDDFBFF) : const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: login ? const Color(0xFF006971) : const Color(0xFF344054),
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final duplicate = lower.contains('duplicate');
    final voided = lower.contains('voided');
    final label = voided
        ? 'Voided'
        : duplicate
        ? 'Duplicate'
        : 'Success';
    final background = voided || duplicate
        ? const Color(0xFFFFF1F1)
        : const Color(0xFFF0FFF6);
    final color = voided || duplicate
        ? AppColors.danger
        : const Color(0xFF16803A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            voided || duplicate ? Icons.warning_amber : Icons.circle,
            color: color,
            size: voided || duplicate ? 19 : 12,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9C2D3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.history, color: AppColors.primary, size: 38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class _ScannerBottomNav extends StatelessWidget {
  const _ScannerBottomNav();

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
          children: const [
            _BottomNavItem(
              'Home',
              Icons.home_outlined,
              AppRoutes.scannerDashboard,
            ),
            _BottomNavItem(
              'Events',
              Icons.calendar_month_outlined,
              AppRoutes.scannerFaceAttendance,
            ),
            _BottomNavItem(
              'Records',
              Icons.description_outlined,
              AppRoutes.scannerHistory,
              selected: true,
            ),
            _BottomNavItem(
              'Scan',
              Icons.face_retouching_natural,
              AppRoutes.scannerFaceAttendance,
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

class _ScanRecord {
  const _ScanRecord({
    required this.studentName,
    required this.studentId,
    required this.courseSection,
    required this.eventName,
    required this.action,
    required this.status,
    required this.timestamp,
    required this.attendanceMethod,
    this.fallbackReason,
    this.voidReason,
    this.voidedAt,
    this.voidedByName,
  });

  final String studentName;
  final String studentId;
  final String courseSection;
  final String eventName;
  final String action;
  final String status;
  final DateTime timestamp;
  final String attendanceMethod;
  final String? fallbackReason;
  final String? voidReason;
  final String? voidedAt;
  final String? voidedByName;

  String get primaryTime => DateFormat('hh:mm a').format(timestamp);

  String get secondaryDate => DateFormat('MMM d, yyyy').format(timestamp);

  factory _ScanRecord.fromModel(AttendedEventModel item) {
    final login = _tryParse(item.loginTime);
    final logout = _tryParse(item.logoutTime);
    final scanned = _tryParse(item.scannedTime);
    final timestamp = scanned ?? logout ?? login ?? DateTime.now();
    final action = logout == null ? 'Login' : 'Logout';
    final status = item.status?.trim().isNotEmpty == true
        ? item.status!
        : 'Success';

    return _ScanRecord(
      studentName: item.studentName ?? 'Student Record',
      studentId: item.studentId ?? 'N/A',
      courseSection: item.courseSection ?? 'Course/section N/A',
      eventName: item.event?.name ?? 'Campus Event',
      action: action,
      status: status,
      timestamp: timestamp,
      attendanceMethod: item.attendanceMethod ?? 'unknown',
      fallbackReason: _nonEmpty(
        item.qrFallbackReason == null
            ? null
            : item.qrFallbackOtherReason == null
            ? item.qrFallbackReason
            : '${item.qrFallbackReason}: ${item.qrFallbackOtherReason}',
      ),
      voidReason: _nonEmpty(item.voidReason),
      voidedAt: _nonEmpty(item.voidedAt),
      voidedByName: _nonEmpty(item.voidedByName),
    );
  }
}

DateTime? _tryParse(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

String? _nonEmpty(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
