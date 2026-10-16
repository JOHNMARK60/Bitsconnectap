import 'dart:async';

import 'package:bits_mobile_app/controllers/scanner_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/utils/date_formatter.dart';
import 'package:bits_mobile_app/core/utils/event_timeline.dart';
import 'package:bits_mobile_app/core/widgets/face_liveness_capture.dart';
import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/models/attendance_result_model.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/screens/scanner/widgets/scanner_logout_button.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FaceAttendanceScannerScreen extends StatefulWidget {
  const FaceAttendanceScannerScreen({super.key});

  @override
  State<FaceAttendanceScannerScreen> createState() =>
      _FaceAttendanceScannerScreenState();
}

class _FaceAttendanceScannerScreenState
    extends State<FaceAttendanceScannerScreen> {
  EventModel? selectedEvent;
  XFile? image;
  AttendanceResultModel? result;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final scanner = context.read<ScannerController>();
        await scanner.loadDashboard();
        await scanner.loadEvents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerController>();
    final currentEvents = EventTimeline.fromEvents(
      scanner.events,
      now: scanner.eventReferenceTime(),
    ).currentEvents.where((event) => event.isAttendancePhaseOpen).toList();
    selectedEvent = _selectedCurrentEvent(currentEvents);
    final disabledMessage = scanner.scannerPolicyMessage(selectedEvent);
    final actionLabel = selectedEvent?.attendanceActionDisplay ?? 'Attendance';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Face Attendance'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: const [ScannerLogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          const Text(
            'Face Attendance',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a current event, complete blink liveness, then capture one student face for Laravel matching.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 17,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<EventModel>(
            key: ValueKey(selectedEvent?.id ?? 'no-current-event'),
            initialValue: scanner.events.contains(selectedEvent)
                ? selectedEvent
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Event',
              border: OutlineInputBorder(),
            ),
            hint: Text(
              scanner.loading
                  ? 'Loading events...'
                  : currentEvents.isEmpty
                  ? 'No event currently open for attendance.'
                  : 'Select Event',
            ),
            items: currentEvents
                .map(
                  (event) => DropdownMenuItem(
                    value: event,
                    child: Text(event.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: submitting || currentEvents.isEmpty
                ? null
                : (event) => setState(() => selectedEvent = event),
          ),
          if (!scanner.loading && currentEvents.isEmpty) ...[
            const SizedBox(height: 12),
            const _EventNotice(
              message: 'No event currently open for attendance.',
            ),
          ] else if (selectedEvent != null) ...[
            const SizedBox(height: 12),
            _SelectedEventCard(event: selectedEvent!),
          ],
          if (disabledMessage != null) ...[
            const SizedBox(height: 18),
            _DisabledPolicyCard(message: disabledMessage),
          ],
          if (scanner.loading && scanner.events.isEmpty) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const _FaceProcessHeader(),
                const SizedBox(height: 18),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(56),
                  ),
                  child: Icon(
                    image == null
                        ? Icons.face_retouching_natural
                        : Icons.check_circle_outline,
                    size: 68,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  image?.name ?? 'Ready for live face capture.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed:
                      submitting ||
                          disabledMessage != null ||
                          currentEvents.isEmpty
                      ? null
                      : _capture,
                  icon: const Icon(Icons.face_retouching_natural),
                  label: Text(
                    submitting ? 'Processing...' : 'Start $actionLabel Scan',
                  ),
                ),
              ],
            ),
          ),
          if (submitting) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (result != null) ...[
            const SizedBox(height: 20),
            _AttendanceResultCard(result: result!),
            if (result!.registrationRequired) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.scannerFaceRegistration,
                ),
                icon: const Icon(Icons.face_retouching_natural),
                label: const Text('Register Face Again'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _capture() async {
    if (submitting) return;

    final disabledMessage = context
        .read<ScannerController>()
        .scannerPolicyMessage(selectedEvent);
    if (disabledMessage != null) {
      _message(disabledMessage);
      return;
    }

    if (selectedEvent == null) {
      _message('Select an event first.');
      return;
    }

    final picked = await FaceLivenessCapture.capture(
      context,
      title: 'Face Attendance',
    );
    if (picked == null || !mounted) return;

    setState(() {
      image = picked;
      submitting = true;
      result = null;
    });

    final scanner = context.read<ScannerController>();
    final attendance = await scanner.scanFaceAttendance(
      eventId: selectedEvent!.id,
      image: picked,
    );
    if (!mounted) return;

    setState(() {
      submitting = false;
      result = attendance;
    });

    if (attendance.success) {
      unawaited(scanner.loadHistory());
    } else if (mounted &&
        attendance.message ==
            'You must be within the allowed campus area to record attendance.') {
      await _attendanceWarning('Outside Campus Area', attendance.message);
    } else if (mounted &&
        attendance.message ==
            'Please allow location access to record attendance.') {
      await _attendanceWarning('Location Required', attendance.message);
    }
  }

  EventModel? _selectedCurrentEvent(List<EventModel> currentEvents) {
    if (currentEvents.isEmpty) return null;
    final selectedId = selectedEvent?.id;
    if (selectedId != null) {
      for (final event in currentEvents) {
        if (event.id == selectedId) return event;
      }
    }
    return currentEvents.first;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _attendanceWarning(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
}

class _FaceProcessHeader extends StatelessWidget {
  const _FaceProcessHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ProcessStep(
          icon: Icons.event_available_outlined,
          text: 'Confirm current event',
        ),
        SizedBox(height: 10),
        _ProcessStep(icon: Icons.visibility_outlined, text: 'Blink once'),
        SizedBox(height: 10),
        _ProcessStep(
          icon: Icons.cloud_done_outlined,
          text: 'Record face attendance',
        ),
      ],
    );
  }
}

class _ProcessStep extends StatelessWidget {
  const _ProcessStep({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EventNotice extends StatelessWidget {
  const _EventNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_outlined, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF92400E),
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

class _SelectedEventCard extends StatelessWidget {
  const _SelectedEventCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _eventSchedule(event),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  event.attendancePhaseDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF16803A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Attendance Mode: ${event.attendanceModeDisplay} • Status: ${event.attendanceOpenDisplay}',
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

class _DisabledPolicyCard extends StatelessWidget {
  const _DisabledPolicyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(10),
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

class _AttendanceResultCard extends StatelessWidget {
  const _AttendanceResultCard({required this.result});

  final AttendanceResultModel result;

  @override
  Widget build(BuildContext context) {
    final success = result.success;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: success ? AppColors.success : AppColors.danger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.verified_outlined : Icons.error_outline,
                color: success ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (result.studentName != null) ...[
            const SizedBox(height: 12),
            _ResultDetail(label: 'Student', value: result.studentName!),
          ],
          if (result.studentId != null)
            _ResultDetail(label: 'Student ID', value: result.studentId!),
          if (result.course != null)
            _ResultDetail(label: 'Course', value: result.course!),
          if (result.yearLevel != null || result.section != null)
            _ResultDetail(
              label: 'Year & Section',
              value: [result.yearLevel, result.section]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join(' - '),
            ),
          if (result.eventName != null) Text('Event: ${result.eventName}'),
          if (result.similarityScore != null)
            Text(
              'Similarity: ${(result.similarityScore! * 100).toStringAsFixed(1)}%',
            ),
        ],
      ),
    );
  }
}

class _ResultDetail extends StatelessWidget {
  const _ResultDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _eventSchedule(EventModel event) {
  final start = _firstNonEmpty([
    event.loginDateTime,
    event.attendanceStartTime,
  ]);
  if (start.isNotEmpty) return DateFormatter.dateTime(start);

  final date = _firstNonEmpty([event.eventDate]);
  if (date.isNotEmpty) return DateFormatter.date(date);

  return 'Schedule not set';
}

String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') return text;
  }
  return '';
}
