import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/scanner_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScannerEventsScreen extends StatefulWidget {
  const ScannerEventsScreen({super.key});

  @override
  State<ScannerEventsScreen> createState() => _ScannerEventsScreenState();
}

class _ScannerEventsScreenState extends State<ScannerEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ScannerController>().loadEvents(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            onPressed: scanner.loadEvents,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh events',
          ),
        ],
      ),
      body: scanner.loading && scanner.events.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : scanner.events.isEmpty
          ? const Center(child: Text('No events available.'))
          : RefreshIndicator(
              onRefresh: scanner.loadEvents,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: scanner.events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final event = scanner.events[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.scannerFaceAttendance,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.event_outlined),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  event.name,
                                  maxLines: 3,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((event.description ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              event.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _EventMeta(
                                icon: Icons.calendar_today_outlined,
                                label: DateFormatter.dateTime(event.eventDate),
                              ),
                              _EventPhaseBadge(
                                label: event.attendancePhaseDisplay,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${event.attendanceModeDisplay} • ${event.attendanceOpenDisplay}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _EventMeta extends StatelessWidget {
  const _EventMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 64,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventPhaseBadge extends StatelessWidget {
  const _EventPhaseBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 64,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
