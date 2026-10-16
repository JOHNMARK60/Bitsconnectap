import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/utils/date_formatter.dart';
import 'package:bits_mobile_app/core/utils/event_timeline.dart';
import 'package:bits_mobile_app/core/widgets/error_view.dart';
import 'package:bits_mobile_app/core/widgets/loading_view.dart';
import 'package:bits_mobile_app/core/widgets/paginated_event_list.dart';
import 'package:bits_mobile_app/models/attended_event_model.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/screens/student/student_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentEventsScreen extends StatefulWidget {
  const StudentEventsScreen({super.key});

  @override
  State<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

class _StudentEventsScreenState extends State<StudentEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StudentController>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentController>();
    final eventTimeline = EventTimeline.fromEvents(
      controller.events,
      now: controller.eventReferenceTime(),
    );

    return StudentChrome(
      currentRoute: AppRoutes.studentEvents,
      onRefresh: controller.loadEvents,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 36),
        children: [
          if (controller.loading && controller.events.isEmpty)
            const SizedBox(height: 520, child: LoadingView())
          else if (controller.error != null && controller.events.isEmpty)
            ErrorView(
              message: controller.error!,
              onRetry: controller.loadEvents,
            )
          else ...[
            const Text(
              'Events & Attendance',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'View available campus events and your attendance records.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 20,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _SummaryPill(
                    icon: Icons.calendar_month,
                    text: '${eventTimeline.currentEvents.length} Available',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryPill(
                    icon: Icons.check_circle,
                    text: '${controller.attendedEvents.length} Attended',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            _EventsPanel(
              title: 'Available Events',
              subtitle: 'Events scheduled today that are still active.',
              events: eventTimeline.currentEvents,
              emptyText: 'No campus events available today.',
              showAction: true,
            ),
            const SizedBox(height: 28),
            _EventsPanel(
              title: 'Upcoming Events',
              subtitle: 'Events scheduled for a future date.',
              events: eventTimeline.upcomingEvents,
              emptyText: 'No upcoming campus events.',
              showAction: false,
            ),
            const SizedBox(height: 28),
            _EventsPanel(
              title: 'Recent Events',
              subtitle: 'Past events and events that are already closed.',
              events: eventTimeline.recentEvents,
              emptyText: 'No recent campus events.',
              showAction: false,
              paginated: true,
            ),
            const SizedBox(height: 28),
            _AttendedPanel(items: controller.attendedEvents),
          ],
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD0E3FF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.child,
  });

  final String title;
  final String subtitle;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 18,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count records',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}

class _EventsPanel extends StatelessWidget {
  const _EventsPanel({
    required this.title,
    required this.subtitle,
    required this.events,
    required this.emptyText,
    required this.showAction,
    this.paginated = false,
  });

  final String title;
  final String subtitle;
  final List<EventModel> events;
  final String emptyText;
  final bool showAction;
  final bool paginated;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      subtitle: subtitle,
      count: events.length,
      child: events.isEmpty
          ? _EmptyBox(text: emptyText)
          : Column(
              children: [
                const _TableHeader(),
                if (paginated)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PaginatedEventList(
                      events: events,
                      itemBuilder: (event) =>
                          _EventRow(event: event, showAction: showAction),
                    ),
                  )
                else
                  for (final event in events)
                    _EventRow(event: event, showAction: showAction),
              ],
            ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 620;

        return Container(
          color: const Color(0xFFF2F6FC),
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 18 : 28,
            vertical: narrow ? 16 : 22,
          ),
          child: Text(
            narrow ? 'EVENT DETAILS' : 'EVENT NAME',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.showAction});

  final EventModel event;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final status = event.attendanceStatus ?? 'pending';
    final loggedIn =
        status == 'logged_in' || status == 'present' || status == 'completed';
    final completed = status == 'completed';
    final attendanceOpen = event.isAttendancePhaseOpen;
    final statusLabel = completed
        ? 'Completed'
        : loggedIn
        ? 'Timed In'
        : event.attendancePhaseDisplay;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return _CompactEventRow(
            event: event,
            showAction: showAction,
            completed: completed,
            attendanceOpen: attendanceOpen,
            statusLabel: statusLabel,
          );
        }

        return _WideEventRow(
          event: event,
          showAction: showAction,
          completed: completed,
          attendanceOpen: attendanceOpen,
          statusLabel: statusLabel,
        );
      },
    );
  }
}

class _WideEventRow extends StatelessWidget {
  const _WideEventRow({
    required this.event,
    required this.showAction,
    required this.completed,
    required this.attendanceOpen,
    required this.statusLabel,
  });

  final EventModel event;
  final bool showAction;
  final bool completed;
  final bool attendanceOpen;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 26, 18, 26),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const _EventIcon(),
          const SizedBox(width: 18),
          Expanded(
            child: _EventDetails(
              event: event,
              showAction: showAction,
              completed: completed,
              attendanceOpen: attendanceOpen,
              statusLabel: statusLabel,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 128,
            child: Text(
              DateFormatter.date(event.eventDate),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactEventRow extends StatelessWidget {
  const _CompactEventRow({
    required this.event,
    required this.showAction,
    required this.completed,
    required this.attendanceOpen,
    required this.statusLabel,
  });

  final EventModel event;
  final bool showAction;
  final bool completed;
  final bool attendanceOpen;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _EventIcon(size: 48, iconSize: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.22,
                  ),
                ),
              ),
            ],
          ),
          if ((event.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              event.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _EventLocation(event: event),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusBadge(label: statusLabel, completed: completed),
              _DateBadge(date: DateFormatter.date(event.eventDate)),
              if (showAction)
                _AttendanceButton(
                  event: event,
                  completed: completed,
                  attendanceOpen: attendanceOpen,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventDetails extends StatelessWidget {
  const _EventDetails({
    required this.event,
    required this.showAction,
    required this.completed,
    required this.attendanceOpen,
    required this.statusLabel,
  });

  final EventModel event;
  final bool showAction;
  final bool completed;
  final bool attendanceOpen;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            height: 1.22,
          ),
        ),
        if ((event.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            event.description!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _EventLocation(event: event),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusBadge(label: statusLabel, completed: completed),
            if (showAction)
              _AttendanceButton(
                event: event,
                completed: completed,
                attendanceOpen: attendanceOpen,
              ),
          ],
        ),
      ],
    );
  }
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({this.size = 54, this.iconSize = 28});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.calendar_month, color: AppColors.royal, size: iconSize),
    );
  }
}

class _EventLocation extends StatelessWidget {
  const _EventLocation({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 17,
          color: AppColors.muted,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Attendance venue: ${event.attendanceVenueLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.completed});

  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFE7F8EF) : const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: completed ? const Color(0xFF16803A) : AppColors.primary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        date,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  const _AttendanceButton({
    required this.event,
    required this.completed,
    required this.attendanceOpen,
  });

  final EventModel event;
  final bool completed;
  final bool attendanceOpen;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFCBD5E1),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: completed || !attendanceOpen
          ? null
          : () => Navigator.pushNamed(context, AppRoutes.studentFaceAttendance),
      icon: const Icon(Icons.face_retouching_natural, size: 18),
      label: Text(
        event.isTimeOutPhase ? 'Time Out' : 'Time In',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AttendedPanel extends StatelessWidget {
  const _AttendedPanel({required this.items});

  final List<AttendedEventModel> items;

  @override
  Widget build(BuildContext context) {
    final sortedItems = [...items]..sort(AttendedEventModel.compareNewestFirst);
    return _Panel(
      title: 'Attended Events',
      subtitle: 'Your recorded login and logout attendance history.',
      count: items.length,
      child: items.isEmpty
          ? const _EmptyBox(text: 'No attended events yet.')
          : Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PaginatedList<AttendedEventModel>(
                items: sortedItems,
                itemId: (item) => item.id,
                pageSize: 1,
                itemBuilder: (item) => ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: Text(item.event?.name ?? 'Campus event'),
                  subtitle: Text(
                    'Login: ${item.loginTime ?? '-'}\nLogout: ${item.logoutTime ?? '-'}',
                  ),
                ),
              ),
            ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 42),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD8E5F7)),
        ),
        child: Column(
          children: [
            const Icon(Icons.assignment_turned_in, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(
              text,
              style: const TextStyle(color: AppColors.muted, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
