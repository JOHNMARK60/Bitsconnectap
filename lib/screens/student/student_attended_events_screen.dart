import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/widgets/paginated_event_list.dart';
import 'package:bits_mobile_app/models/attended_event_model.dart';
import 'package:bits_mobile_app/screens/student/student_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StudentAttendedEventsScreen extends StatefulWidget {
  const StudentAttendedEventsScreen({super.key});

  @override
  State<StudentAttendedEventsScreen> createState() =>
      _StudentAttendedEventsScreenState();
}

class _StudentAttendedEventsScreenState
    extends State<StudentAttendedEventsScreen> {
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final controller = context.read<StudentController>();
        await controller.loadAttendedEvents();
        await controller.loadPenalties();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentController>();
    final sortedItems = [...controller.attendedEvents]
      ..sort(AttendedEventModel.compareNewestFirst);
    final records = sortedItems.map(_AttendanceRecord.fromModel).toList();
    final visibleRecords = _filter(records);

    return StudentChrome(
      currentRoute: AppRoutes.studentAttendedEvents,
      onRefresh: controller.loadAttendedEvents,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 36),
        children: [
          const Text(
            'Attendance History',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Review your participation in campus events and academic sessions.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 20,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),
          _FilterTabs(
            selectedIndex: _filterIndex,
            onChanged: (index) => setState(() => _filterIndex = index),
          ),
          const SizedBox(height: 36),
          if (controller.loading)
            const SizedBox(
              height: 360,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.error != null)
            _StateCard(
              icon: Icons.error_outline,
              title: 'Unable to load records',
              message: controller.error!,
              onRetry: controller.loadAttendedEvents,
            )
          else if (visibleRecords.isEmpty)
            const _StateCard(
              icon: Icons.fact_check_outlined,
              title: 'No records found',
              message: 'Try another filter or check again later.',
            )
          else
            PaginatedList<_AttendanceRecord>(
              key: ValueKey(_filterIndex),
              items: visibleRecords,
              itemId: (record) => record.id,
              pageSize: 1,
              itemBuilder: (record) => _TimelineList(records: [record]),
            ),
          const SizedBox(height: 36),
          _MonthlyStats(records: records),
          const SizedBox(height: 28),
          _PenaltyPanel(items: controller.penalties),
        ],
      ),
    );
  }

  List<_AttendanceRecord> _filter(List<_AttendanceRecord> records) {
    if (_filterIndex == 1) {
      final now = DateTime.now();
      return records
          .where(
            (record) =>
                record.date.year == now.year && record.date.month == now.month,
          )
          .toList();
    }
    if (_filterIndex == 2) {
      return records
          .where((record) => record.title.toLowerCase().contains('workshop'))
          .toList();
    }
    return records;
  }
}

class _PenaltyPanel extends StatelessWidget {
  const _PenaltyPanel({required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Penalties',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const Text(
            'No attendance penalties.',
            style: TextStyle(color: AppColors.muted),
          )
        else
          for (final item in items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule, color: AppColors.danger),
                title: Text(item['event_name']?.toString() ?? 'Campus Event'),
                subtitle: Text(_penaltySubtitle(item)),
                trailing: Text(
                  item['status']?.toString().toUpperCase() ?? 'PENDING',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
      ],
    ),
  );
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['All Records', 'This Month', 'Workshops'];

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: _FilterPill(
              label: labels[i],
              selected: selectedIndex == i,
              onTap: () => onChanged(i),
            ),
          ),
          if (i != labels.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 47,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFB9C2D3),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.records});

  final List<_AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < records.length; i++)
          _TimelineEntry(
            record: records[i],
            isFirst: i == 0,
            isLast: i == records.length - 1,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.record,
    required this.isFirst,
    required this.isLast,
  });

  final _AttendanceRecord record;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final iconColor = isFirst ? AppColors.primary : const Color(0xFFDCEBFF);
    final iconForeground = isFirst ? Colors.white : const Color(0xFF344054);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 54,
            child: Column(
              children: [
                if (!isFirst) const Expanded(child: _TimelineRail()),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                    border: isFirst
                        ? null
                        : Border.all(color: const Color(0xFFB9CBE5)),
                  ),
                  child: Icon(
                    isFirst ? Icons.calendar_today_outlined : Icons.history,
                    color: iconForeground,
                    size: 26,
                  ),
                ),
                if (!isLast) const Expanded(child: _TimelineRail()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 44),
              child: _AttendanceCard(record: record),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail();

  @override
  Widget build(BuildContext context) {
    return Container(width: 2, color: const Color(0xFFDCE6F2));
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record});

  final _AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final partial =
        record.status.toLowerCase().contains('partial') ||
        record.checkOut == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  record.dateLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _StatusBadge(partial: partial),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _TimeMeta(
                  icon: Icons.schedule,
                  label: 'Check-in',
                  value: _timeLabel(record.checkIn),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TimeMeta(
                      icon: Icons.logout,
                      label: 'Check-out',
                      value: _timeLabel(record.checkOut),
                      danger: partial,
                    ),
                    if (record.isLate) ...[
                      const SizedBox(height: 12),
                      _LateBadge(minutes: record.lateMinutes),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (record.isLate && record.lateReason != null) ...[
            const SizedBox(height: 16),
            _TimeMeta(
              icon: Icons.info_outline,
              label: 'Late note',
              value: record.lateReason!,
              danger: true,
            ),
          ],
          if (record.location.isNotEmpty) ...[
            const SizedBox(height: 20),
            _TimeMeta(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: record.location,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.partial});

  final bool partial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: partial ? const Color(0xFFE5EEFF) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        partial ? 'Partial' : 'Completed',
        style: TextStyle(
          color: partial ? const Color(0xFF344054) : const Color(0xFF16803A),
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _LateBadge extends StatelessWidget {
  const _LateBadge({required this.minutes});

  final int? minutes;

  @override
  Widget build(BuildContext context) {
    final text = minutes == null || minutes! <= 0
        ? 'Late Time-In'
        : 'Late Time-In - ${minutes}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFC2410C),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TimeMeta extends StatelessWidget {
  const _TimeMeta({
    required this.icon,
    required this.label,
    required this.value,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(
          icon,
          color: danger ? AppColors.danger : const Color(0xFF6B7280),
          size: 26,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: danger ? AppColors.danger : AppColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyStats extends StatelessWidget {
  const _MonthlyStats({required this.records});

  final List<_AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final completed = records.where((record) => record.checkOut != null).length;
    final totalHours = records.fold<double>(0, (sum, record) {
      if (record.checkOut == null) return sum;
      return sum + record.checkOut!.difference(record.checkIn).inMinutes / 60;
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 34, 32, 32),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF075FC7), Color(0xFF096ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Statistics',
            style: TextStyle(
              color: Color(0xFFD3DFFF),
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Total Hours',
                  value: '${totalHours.toStringAsFixed(1)}h',
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: _StatBox(
                  label: 'Events Attended',
                  value: completed.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 18, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFADC6FF),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFD3DFFF),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB9C2D3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
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

class _AttendanceRecord {
  const _AttendanceRecord({
    required this.title,
    required this.date,
    required this.id,
    required this.checkIn,
    required this.checkOut,
    required this.location,
    required this.status,
    required this.isLate,
    this.lateMinutes,
    this.lateReason,
  });

  final String title;
  final int id;
  final DateTime date;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String location;
  final String status;
  final bool isLate;
  final int? lateMinutes;
  final String? lateReason;

  String get dateLabel {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'TODAY';
    }
    return DateFormat('MMM d, yyyy').format(date).toUpperCase();
  }

  factory _AttendanceRecord.fromModel(AttendedEventModel model) {
    final checkIn =
        _tryParse(model.loginTime) ??
        _tryParse(model.scannedTime) ??
        DateTime.now();
    final checkOut = _tryParse(model.logoutTime);
    final event = model.event;
    final location = [
      event?.academicYear,
      event?.semester,
    ].whereType<String>().where((item) => item.trim().isNotEmpty).join(', ');

    return _AttendanceRecord(
      id: model.id,
      title: event?.name ?? 'Campus Event',
      date: _tryParse(event?.eventDate) ?? checkIn,
      checkIn: checkIn,
      checkOut: checkOut,
      location: location,
      status: model.status ?? (checkOut == null ? 'Partial' : 'Completed'),
      isLate: model.isLate,
      lateMinutes: model.lateMinutes,
      lateReason: model.lateReason,
    );
  }
}

DateTime? _tryParse(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

String _timeLabel(DateTime? value) {
  if (value == null) return 'N/A';
  return DateFormat('hh:mm a').format(value);
}

String? _formatOptionalDate(String? value) {
  final parsed = _tryParse(value);
  if (parsed == null) return null;
  return DateFormat('MMM d, yyyy').format(parsed);
}

String _penaltySubtitle(Map<String, dynamic> item) {
  return [
    '${item['value']} ${item['unit']}',
    item['reason']?.toString(),
    _formatOptionalDate(item['created_at']?.toString()),
  ].where((value) => value != null && value.trim().isNotEmpty).join(' - ');
}
