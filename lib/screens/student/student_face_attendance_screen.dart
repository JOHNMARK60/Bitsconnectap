import 'dart:async';

import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/services/device_integrity_service.dart';
import 'package:bits_mobile_app/core/services/location_service.dart';
import 'package:bits_mobile_app/core/utils/event_timeline.dart';
import 'package:bits_mobile_app/core/utils/date_formatter.dart';
import 'package:bits_mobile_app/core/utils/geofence_helper.dart';
import 'package:bits_mobile_app/core/widgets/face_liveness_capture.dart';
import 'package:bits_mobile_app/models/attendance_result_model.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/screens/student/student_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class StudentFaceAttendanceScreen extends StatefulWidget {
  const StudentFaceAttendanceScreen({super.key});

  @override
  State<StudentFaceAttendanceScreen> createState() =>
      _StudentFaceAttendanceScreenState();
}

class _StudentFaceAttendanceScreenState
    extends State<StudentFaceAttendanceScreen>
    with WidgetsBindingObserver {
  static const _attendanceOffMessage =
      'Attendance is currently unavailable. Please wait for the administrator to open it.';
  static const _closedEventMessage = 'This event is already closed.';
  static const _emptyEventsMessage =
      'No available events for facial attendance at this time.';

  final _locationService = LocationService();
  final _deviceIntegrity = DeviceIntegrityService();
  EventModel? _selectedEvent;
  Position? _position;
  double? _distance;
  bool _attendanceEnabled = true;
  bool? _developerOptionsEnabled;
  String _staticIpStatus = 'optional_unavailable';
  String? _validationMessage;
  AttendanceResultModel? _result;
  bool _loadingContext = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshFaceAttendanceData());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_refreshFaceAttendanceData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentController>();
    final user = context.watch<AuthController>().user;
    final referenceTime = student.eventReferenceTime();
    final faceEvents = _faceEventOptions(student.events, referenceTime);
    _selectedEvent = _selectedEventOption(faceEvents);
    final allowedRadius = GeofenceHelper.allowedRadiusForVenue(
      _selectedEvent?.attendanceVenue,
    );
    final geotagAccepted = _distance != null && _distance! <= allowedRadius;
    final canSubmit =
        !_submitting &&
        !_loadingContext &&
        student.profileComplete &&
        !student.newDeviceDetected &&
        _selectedEvent != null &&
        _selectedEvent!.isAttendancePhaseOpen;
    final actionLabel = _selectedEvent?.attendanceActionDisplay ?? 'Scan';
    final emptyFaceMessage = faceEvents.isEmpty
        ? _closedOrEmptyMessage(student.events, referenceTime)
        : _emptyEventsMessage;

    return StudentChrome(
      currentRoute: AppRoutes.studentFaceAttendance,
      onRefresh: _refreshFaceAttendanceData,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          const Text(
            'Face Attendance',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _AccountPanel(
            name: user?.fullName ?? 'Student',
            email: user?.email ?? '',
            registered: student.faceRegistered == true,
          ),
          if (!student.profileComplete) ...[
            const SizedBox(height: 14),
            _ProfileGateCard(
              completion: student.profileCompletion,
              missingFields: student.profileMissingFields,
              onOpenProfile: () =>
                  Navigator.pushNamed(context, AppRoutes.studentProfile),
            ),
          ],
          const SizedBox(height: 18),
          DropdownButtonFormField<EventModel>(
            key: ValueKey(_selectedEvent?.id ?? 'no-current-event'),
            initialValue: _selectedEvent,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Choose Event',
              border: OutlineInputBorder(),
            ),
            hint: Text(
              student.loading
                  ? 'Loading events...'
                  : faceEvents.isEmpty
                  ? emptyFaceMessage
                  : 'Select Event',
            ),
            items: faceEvents
                .map(
                  (event) => DropdownMenuItem(
                    value: event,
                    child: Text(event.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _submitting || faceEvents.isEmpty
                ? null
                : (event) => setState(() {
                    _selectedEvent = event;
                    _validationMessage = null;
                    _result = null;
                  }),
          ),
          if (!_attendanceEnabled) ...[
            const SizedBox(height: 12),
            const _InlineNotice(
              icon: Icons.block_outlined,
              message: _attendanceOffMessage,
            ),
          ] else if (!student.loading && faceEvents.isEmpty) ...[
            const SizedBox(height: 12),
            _InlineNotice(
              icon: Icons.event_busy_outlined,
              message: emptyFaceMessage,
            ),
          ],
          if (_selectedEvent != null) ...[
            const SizedBox(height: 12),
            _InlineNotice(
              icon: Icons.fact_check_outlined,
              message:
                  'Attendance Mode: ${_selectedEvent!.attendanceModeDisplay}\nStatus: ${_selectedEvent!.attendanceOpenDisplay}${_selectedEvent!.attendanceWindowEnd == null ? '' : '\nWindow closes: ${DateFormatter.dateTime(_selectedEvent!.attendanceWindowEnd!)}'}${_selectedEvent!.attendanceWasExtended ? '\nAdministrator extended this window.' : ''}',
            ),
          ],
          const SizedBox(height: 18),
          _ValidationPanel(
            items: [
              _ValidationItem(
                icon: Icons.person_outline,
                title: 'Student Profile',
                detail: student.profileComplete
                    ? 'Complete'
                    : '${student.profileCompletion}% complete',
                state: student.profileComplete
                    ? _ValidationState.success
                    : _ValidationState.error,
              ),
              _ValidationItem(
                icon: Icons.location_on_outlined,
                title: 'Geotag',
                detail: _distance == null
                    ? 'Not checked · Allowed ${allowedRadius.toStringAsFixed(0)}m'
                    : '${_distance!.toStringAsFixed(1)}m / ${allowedRadius.toStringAsFixed(0)}m allowed',
                state: _distance == null
                    ? _ValidationState.pending
                    : geotagAccepted
                    ? _ValidationState.success
                    : _ValidationState.error,
              ),
              _ValidationItem(
                icon: Icons.wifi_tethering_outlined,
                title: 'Static IP Optional',
                detail: _staticIpStatus == 'available'
                    ? 'Available'
                    : 'Optional',
                state: _ValidationState.success,
              ),
              _ValidationItem(
                icon: Icons.developer_mode_outlined,
                title: 'Developer Options',
                detail: _developerOptionsEnabled == null
                    ? 'Not checked'
                    : _developerOptionsEnabled!
                    ? 'Enabled'
                    : 'Disabled',
                state: _developerOptionsEnabled == null
                    ? _ValidationState.pending
                    : _developerOptionsEnabled!
                    ? _ValidationState.error
                    : _ValidationState.success,
              ),
              _ValidationItem(
                icon: Icons.event_available_outlined,
                title: 'Choose Event',
                detail: _selectedEvent?.name ?? 'Required',
                state: _selectedEvent == null
                    ? _ValidationState.pending
                    : _ValidationState.success,
              ),
            ],
          ),
          if (student.newDeviceDetected &&
              (student.faceStatusMessage ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                student.faceStatusMessage!,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
          if (_validationMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _validationMessage!,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: canSubmit ? _startScan : null,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: Text(_submitting ? 'Saving...' : 'Start $actionLabel Scan'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultPanel(result: _result!),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshFaceAttendanceData() async {
    final student = context.read<StudentController>();
    await student.loadProfile();
    await student.loadEvents();
    await student.loadFaceStatus();
    await _loadValidationContext();
  }

  Future<void> _loadValidationContext() async {
    setState(() => _loadingContext = true);
    try {
      final data = await context
          .read<StudentController>()
          .loadAttendanceValidationContext();
      final staticIp = Map<String, dynamic>.from(
        data['static_ip'] as Map? ?? {},
      );
      final attendance = Map<String, dynamic>.from(
        data['attendance'] as Map? ?? {},
      );
      if (mounted) {
        setState(() {
          _staticIpStatus =
              staticIp['status']?.toString() ?? 'optional_unavailable';
          _attendanceEnabled = attendance['enabled'] != false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _staticIpStatus = 'optional_unavailable');
      }
    } finally {
      if (mounted) setState(() => _loadingContext = false);
    }
  }

  Future<bool> _validateBeforeCapture() async {
    final student = context.read<StudentController>();
    await _refreshFaceAttendanceData();
    if (!mounted) return false;

    if (!_attendanceEnabled) {
      setState(() {
        _validationMessage = _attendanceOffMessage;
      });
      return false;
    }

    if (!student.profileComplete) {
      setState(() {
        _validationMessage =
            'Please complete your student profile and upload a profile photo before attendance.';
      });
      return false;
    }

    if (student.newDeviceDetected) {
      setState(() {
        _validationMessage =
            student.faceStatusMessage ??
            'New device detected. Your face is already registered on another device. Please contact the administrator to reset your face registration.';
      });
      return false;
    }

    final referenceTime = student.eventReferenceTime();
    final faceEvents = _faceEventOptions(student.events, referenceTime);
    if (_selectedEvent != null &&
        !faceEvents.any((event) => event.id == _selectedEvent!.id)) {
      setState(() {
        _selectedEvent = null;
        _validationMessage = _closedOrEmptyMessage(
          student.events,
          referenceTime,
        );
      });
      return false;
    }
    final latestSelected = _latestEventById(student.events, _selectedEvent?.id);
    if (_selectedEvent != null && latestSelected == null) {
      setState(() {
        _selectedEvent = null;
        _validationMessage = _closedEventMessage;
      });
      return false;
    }
    final closedMessage = _eventClosedMessage(latestSelected);
    if (closedMessage != null) {
      setState(() {
        _selectedEvent = null;
        _validationMessage = closedMessage;
      });
      return false;
    }

    if (student.faceRegistered != true) {
      setState(() {
        _validationMessage = 'Face registration is required before attendance.';
      });
      return false;
    }

    if (_selectedEvent == null) {
      setState(() {
        _validationMessage = faceEvents.isEmpty
            ? _closedOrEmptyMessage(student.events, referenceTime)
            : 'Please select an event before scanning.';
      });
      return false;
    }

    final developerOptions = await _deviceIntegrity.isDeveloperOptionsEnabled();
    if (!mounted) return false;
    setState(() => _developerOptionsEnabled = developerOptions);
    if (developerOptions) {
      await student.saveAttendanceValidationLog({
        'event_id': _selectedEvent!.id,
        'log_type': 'developer_options',
        'result': 'blocked',
        'message': 'Please disable Developer Options to continue.',
        'static_ip_status': _staticIpStatus,
        'developer_options_enabled': true,
      });
      if (mounted) {
        await _developerOptionsDialog();
      }
      return false;
    }

    try {
      final position = await _locationService.getCurrentLocation();
      final distance = GeofenceHelper.calculateDistanceToVenue(
        position.latitude,
        position.longitude,
        _selectedEvent?.attendanceVenue,
      );
      final radius = GeofenceHelper.allowedRadiusForVenue(
        _selectedEvent?.attendanceVenue,
      );
      if (!mounted) return false;
      setState(() {
        _position = position;
        _distance = distance;
        _validationMessage = distance <= radius
            ? null
            : GeofenceHelper.outsideRadiusMessage;
      });

      if (distance > radius) {
        await student.saveAttendanceValidationLog({
          'event_id': _selectedEvent!.id,
          'log_type': 'geotag',
          'result': 'blocked',
          'message': GeofenceHelper.outsideRadiusMessage,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'geotag_distance': distance,
          'geotag_status': 'rejected',
          'static_ip_status': _staticIpStatus,
          'developer_options_enabled': false,
        });
        return false;
      }

      return true;
    } on LocationServiceException catch (error) {
      if (mounted) {
        setState(() => _validationMessage = error.message);
      }
      return false;
    }
  }

  Future<void> _startScan() async {
    if (!await _validateBeforeCapture() || !mounted) return;

    try {
      final image = await FaceLivenessCapture.capture(
        context,
        title: 'Face Attendance',
      );
      if (image == null || !mounted) return;

      setState(() {
        _submitting = true;
        _result = null;
      });
      final position = _position!;
      final result = await context
          .read<StudentController>()
          .submitFaceAttendance(
            eventId: _selectedEvent!.id,
            image: image,
            latitude: position.latitude,
            longitude: position.longitude,
            distance: _distance!,
            staticIpStatus: _staticIpStatus,
            developerOptionsEnabled: false,
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _result = result;
        _validationMessage = result.success ? null : result.message;
      });
      if (result.registrationRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your face registration needs to be updated before attendance.',
            ),
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.studentFaceRegistration,
        );
        return;
      }
      if (result.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _validationMessage = 'Unable to process face attendance.';
      });
    }
  }

  Future<void> _developerOptionsDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Options Detected'),
        content: const Text('Please disable Developer Options to continue.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

extension on _StudentFaceAttendanceScreenState {
  List<EventModel> _faceEventOptions(List<EventModel> events, DateTime now) {
    return EventTimeline.fromEvents(
      events,
      now: now,
    ).currentEvents.where((event) => event.isAttendancePhaseOpen).toList();
  }

  EventModel? _selectedEventOption(List<EventModel> faceEvents) {
    if (faceEvents.isEmpty) return null;
    final selectedId = _selectedEvent?.id;
    if (selectedId != null) {
      for (final event in faceEvents) {
        if (event.id == selectedId) return event;
      }
    }
    return faceEvents.first;
  }

  EventModel? _latestEventById(List<EventModel> events, int? eventId) {
    if (eventId == null) return null;
    for (final event in events) {
      if (event.id == eventId) return event;
    }
    return null;
  }

  String? _eventClosedMessage(EventModel? event) {
    if (event == null) return null;
    if (!event.isAttendancePhaseOpen) {
      return event.attendancePhaseMessage;
    }
    if (event.isClosedForFaceAttendance()) {
      return _StudentFaceAttendanceScreenState._closedEventMessage;
    }
    return null;
  }

  String _closedOrEmptyMessage(List<EventModel> events, DateTime now) {
    final availableEvents = EventTimeline.fromEvents(
      events,
      now: now,
    ).currentEvents;
    if (availableEvents.isEmpty) {
      return _StudentFaceAttendanceScreenState._emptyEventsMessage;
    }

    return availableEvents.first.attendancePhaseMessage;
  }
}

extension on EventModel {
  bool isClosedForFaceAttendance() {
    return !attendanceEnabled;
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileGateCard extends StatelessWidget {
  const _ProfileGateCard({
    required this.completion,
    required this.missingFields,
    required this.onOpenProfile,
  });

  final int completion;
  final List<String> missingFields;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final missing = missingFields.isEmpty
        ? 'Complete the required student information and upload a profile photo.'
        : 'Missing: ${missingFields.join(', ')}.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete your profile before attendance',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$completion% complete. $missing',
            style: const TextStyle(color: Color(0xFF92400E), height: 1.35),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenProfile,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Complete profile'),
          ),
        ],
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({
    required this.name,
    required this.email,
    required this.registered,
  });

  final String name;
  final String email;
  final bool registered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            registered ? Icons.verified_user : Icons.no_accounts_outlined,
            color: registered ? AppColors.success : AppColors.danger,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            registered ? 'Registered' : 'Not Registered',
            style: TextStyle(
              color: registered ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({required this.items});

  final List<_ValidationItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Validation Checklist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          for (final item in items) _ValidationRow(item: item),
        ],
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({required this.item});

  final _ValidationItem item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.state) {
      _ValidationState.success => AppColors.success,
      _ValidationState.error => AppColors.danger,
      _ValidationState.pending => AppColors.muted,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(item.icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(
            child: Text(
              item.detail,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result});

  final AttendanceResultModel result;

  @override
  Widget build(BuildContext context) {
    final success = result.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
                success ? Icons.check_circle : Icons.error_outline,
                color: success ? AppColors.success : AppColors.danger,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (result.eventName != null) _Detail('Event', result.eventName!),
          if (result.recordedTime != null)
            _Detail('Time', result.recordedTime!),
          if (result.geotagDistance != null)
            _Detail(
              'Location',
              '${result.geotagDistance!.toStringAsFixed(1)}m',
            ),
          if (result.staticIpStatus != null)
            _Detail('Static IP', result.staticIpStatus!),
          if (result.similarityScore != null)
            _Detail(
              'Face Match',
              '${(result.similarityScore! * 100).toStringAsFixed(1)}%',
            ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationItem {
  const _ValidationItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.state,
  });

  final IconData icon;
  final String title;
  final String detail;
  final _ValidationState state;
}

enum _ValidationState { pending, success, error }
