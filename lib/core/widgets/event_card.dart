import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/utils/date_formatter.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  const EventCard({required this.event, super.key});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (event.attendanceStatus != null)
                  Chip(
                    label: Text(event.attendanceStatus!),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.teal.withValues(alpha: .12),
                  ),
              ],
            ),
            if (event.description?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                event.description!,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Meta(
                  Icons.event_outlined,
                  DateFormatter.date(event.eventDate),
                ),
                _Meta(Icons.login, DateFormatter.dateTime(event.loginDateTime)),
                _Meta(
                  Icons.logout,
                  DateFormatter.dateTime(event.logoutDateTime),
                ),
                _Meta(Icons.school_outlined, event.academicYear ?? 'Not set'),
                _Meta(Icons.layers_outlined, event.semester ?? 'Not set'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
