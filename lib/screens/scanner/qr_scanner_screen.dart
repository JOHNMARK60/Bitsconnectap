import 'dart:async';
import 'dart:convert';

import 'package:bits_mobile_app/controllers/scanner_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/services/scan_sound_service.dart';
import 'package:bits_mobile_app/core/utils/event_timeline.dart';
import 'package:bits_mobile_app/models/event_model.dart';
import 'package:bits_mobile_app/screens/scanner/widgets/scanner_logout_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  static const _qrFallbackReasons = [
    'phone unavailable',
    'phone battery empty',
    'phone broken',
    'camera problem',
    'face recognition failed',
    'no mobile data',
    'emergency/manual override',
    'other',
  ];

  static const _qrVoidReasons = [
    'QR code presented by another person',
    'Student was not physically present',
    'Incorrect student record',
    'Duplicate attendance',
    'Invalid facial verification',
    'Other',
  ];

  final MobileScannerController camera = MobileScannerController(
    autoStart: false,
  );
  final ScanSoundService _scanSoundService = ScanSoundService();
  final TextEditingController _fallbackOtherController =
      TextEditingController();
  EventModel? selectedEvent;
  bool cameraStarted = false;
  bool processing = false;
  String? statusMessage;
  DateTime? lastScanAt;
  String? _lastSoundCode;
  DateTime? _lastSoundAt;
  String? _pendingQrCode;
  String? _fallbackReason;
  bool switchingCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Permission.camera.request();
      if (mounted) {
        final scanner = context.read<ScannerController>();
        await scanner.loadDashboard();
        await scanner.loadEvents();
      }
    });
  }

  @override
  void dispose() {
    _fallbackOtherController.dispose();
    _scanSoundService.dispose();
    camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerController>();
    final openEvents = EventTimeline.fromEvents(
      scanner.events,
      now: scanner.eventReferenceTime(),
    ).currentEvents.where((event) => event.isAttendancePhaseOpen).toList();
    if (selectedEvent != null &&
        !openEvents.any((event) => event.id == selectedEvent!.id)) {
      selectedEvent = null;
    }
    if (selectedEvent == null && openEvents.isNotEmpty) {
      selectedEvent = openEvents.first;
    }
    final verified = scanner.verifiedStudent;
    final disabledMessage = _policyMessage(scanner);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: const [ScannerLogoutButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(48, 46, 48, 40),
          children: [
            const Center(
              child: Text(
                'Select Event',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 18),
            _EventSelector(
              events: openEvents,
              selectedEvent: selectedEvent,
              loading: scanner.loading,
              onChanged: (event) async {
                if (cameraStarted) await _stopCamera();
                setState(() {
                  selectedEvent = event;
                  statusMessage = _policyMessage(scanner);
                  _pendingQrCode = null;
                });
              },
            ),
            if (disabledMessage != null) ...[
              const SizedBox(height: 16),
              _DisabledPolicyCard(message: disabledMessage),
            ],
            const SizedBox(height: 36),
            const Center(
              child: Text(
                'Scan QR Code',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(thickness: 2, color: Color(0xFFD8DDE5)),
            const SizedBox(height: 34),
            if (cameraStarted && disabledMessage == null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 320,
                  child: MobileScanner(
                    controller: camera,
                    onDetect: _handleDetect,
                  ),
                ),
              ),
            if (cameraStarted && disabledMessage == null)
              const SizedBox(height: 26),
            Center(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(260, 76),
                  backgroundColor: const Color(0xFF1677FF),
                  textStyle: const TextStyle(fontSize: 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: disabledMessage != null || cameraStarted
                    ? null
                    : _startCamera,
                child: const Text('Start Camera'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(260, 76),
                  textStyle: const TextStyle(fontSize: 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: cameraStarted ? _stopCamera : null,
                child: const Text('Stop Camera'),
              ),
            ),
            if (cameraStarted && disabledMessage == null) ...[
              const SizedBox(height: 16),
              Center(
                child: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: camera,
                  builder: (context, state, _) {
                    final cameraLabel =
                        state.cameraDirection == CameraFacing.front
                        ? 'Front Camera'
                        : 'Back Camera';

                    return OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(260, 76),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        textStyle: const TextStyle(fontSize: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      onPressed: switchingCamera ? null : _switchCamera,
                      icon: const Icon(Icons.cameraswitch_outlined, size: 28),
                      label: Text(
                        switchingCamera
                            ? 'Switching Camera...'
                            : 'Switch Camera ($cameraLabel)',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: camera,
                  builder: (context, state, _) {
                    final torchOn = state.torchState == TorchState.on;

                    return OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(260, 76),
                        foregroundColor: torchOn
                            ? AppColors.warning
                            : AppColors.primary,
                        side: BorderSide(
                          color: torchOn
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
                        textStyle: const TextStyle(fontSize: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      onPressed: _toggleTorch,
                      icon: Icon(
                        torchOn
                            ? Icons.flash_on_outlined
                            : Icons.flash_off_outlined,
                        size: 28,
                      ),
                      label: Text(torchOn ? 'Torch On' : 'Torch Off'),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(260, 76),
                  foregroundColor: const Color(0xFF1677FF),
                  side: const BorderSide(color: Color(0xFF1677FF)),
                  textStyle: const TextStyle(fontSize: 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: disabledMessage != null || processing
                    ? null
                    : _takeQrPhoto,
                child: const Text('Take QR Photo'),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Live scan may require HTTPS on phones. If the camera does not start, use Take QR Photo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: statusMessage!.toLowerCase().contains('error')
                      ? AppColors.danger
                      : AppColors.primary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Student Details',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            if (verified != null) ...[
              _LastScannedCard(data: verified),
              const SizedBox(height: 14),
            ],
            _StudentDetailsCard(data: verified),
            if (_pendingQrCode != null && verified != null) ...[
              const SizedBox(height: 18),
              _ConfirmationPanel(
                hasFaceRegistration: _hasFaceRegistration(verified),
                fallbackReasons: _qrFallbackReasons,
                selectedFallbackReason: _fallbackReason,
                fallbackOtherController: _fallbackOtherController,
                processing: processing,
                onFallbackChanged: (value) =>
                    setState(() => _fallbackReason = value),
                onConfirm: _confirmAttendance,
                onVoid: _voidAttendance,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startCamera() async {
    final disabledMessage = _policyMessage(context.read<ScannerController>());
    if (disabledMessage != null) {
      setState(() => statusMessage = disabledMessage);
      return;
    }

    setState(() => cameraStarted = true);
    await camera.start();
  }

  Future<void> _stopCamera() async {
    await camera.stop();
    if (mounted) setState(() => cameraStarted = false);
  }

  Future<void> _switchCamera() async {
    if (!cameraStarted || switchingCamera) return;

    setState(() {
      switchingCamera = true;
      statusMessage = 'Switching camera...';
    });

    try {
      await camera.switchCamera();
      if (!mounted) return;
      final cameraLabel = camera.value.cameraDirection == CameraFacing.front
          ? 'front camera'
          : 'back camera';
      setState(() => statusMessage = 'Using $cameraLabel.');
    } catch (_) {
      if (!mounted) return;
      setState(() => statusMessage = 'Unable to switch camera on this device.');
    } finally {
      if (mounted) setState(() => switchingCamera = false);
    }
  }

  Future<void> _toggleTorch() async {
    if (!cameraStarted) return;

    try {
      await camera.toggleTorch();
    } catch (_) {
      if (mounted) {
        setState(
          () => statusMessage = 'Torch is not available on this device.',
        );
      }
    }
  }

  Future<void> _takeQrPhoto() async {
    final disabledMessage = _policyMessage(context.read<ScannerController>());
    if (disabledMessage != null) {
      setState(() => statusMessage = disabledMessage);
      return;
    }

    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image == null) return;
    final capture = await camera.analyzeImage(image.path);
    final code = capture?.barcodes.isEmpty == true
        ? null
        : capture?.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) {
      setState(() => statusMessage = 'No QR code found in the photo.');
      return;
    }
    _playScanSound(code);
    await _processCode(code);
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;
    _playScanSound(code);
    await _processCode(code);
  }

  void _playScanSound(String code) {
    final now = DateTime.now();
    if (_lastSoundCode == code &&
        _lastSoundAt != null &&
        now.difference(_lastSoundAt!).inSeconds < 3) {
      return;
    }

    _lastSoundCode = code;
    _lastSoundAt = now;
    unawaited(_scanSoundService.playCaptureSound());
  }

  Future<void> _processCode(String code) async {
    if (processing) return;
    final disabledMessage = _policyMessage(context.read<ScannerController>());
    if (disabledMessage != null) {
      setState(() => statusMessage = disabledMessage);
      return;
    }

    if (lastScanAt != null &&
        DateTime.now().difference(lastScanAt!).inSeconds < 3) {
      return;
    }
    if (selectedEvent == null) {
      setState(() => statusMessage = 'Please select an event first.');
      return;
    }

    setState(() {
      processing = true;
      statusMessage = 'Verifying student...';
      lastScanAt = DateTime.now();
      _pendingQrCode = null;
    });

    final scanner = context.read<ScannerController>();
    final verified = await scanner.verifyQr(code, eventId: selectedEvent!.id);
    if (verified == null) {
      if (mounted) {
        setState(() {
          processing = false;
          statusMessage = scanner.error ?? 'Unable to verify QR code.';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      processing = false;
      statusMessage = 'QR verified. Confirm the student is physically present.';
      _pendingQrCode = code;
      _fallbackReason = null;
      _fallbackOtherController.clear();
    });
  }

  Future<void> _confirmAttendance() async {
    if (_pendingQrCode == null || selectedEvent == null || processing) return;

    final verified = context.read<ScannerController>().verifiedStudent;
    final hasFaceRegistration = _hasFaceRegistration(verified);
    if (hasFaceRegistration && _fallbackReason == null) {
      setState(() {
        statusMessage =
            'This student already has face registration. QR attendance requires a reason.';
      });
      return;
    }
    if (_fallbackReason == 'other' &&
        _fallbackOtherController.text.trim().isEmpty) {
      setState(() => statusMessage = 'Please describe the QR fallback reason.');
      return;
    }

    setState(() {
      processing = true;
      statusMessage = 'Saving attendance...';
    });

    final scanner = context.read<ScannerController>();
    final result = await scanner.scan(
      _pendingQrCode!,
      selectedEvent!.id,
      qrFallbackReason: hasFaceRegistration ? _fallbackReason : null,
      qrFallbackOtherReason: hasFaceRegistration
          ? _fallbackOtherController.text.trim()
          : null,
    );
    if (!mounted) return;
    if (result.message ==
        'You must be within the allowed campus area to record attendance.') {
      await _attendanceWarning('Outside Campus Area', result.message);
    } else if (result.status == 'error' &&
        (result.message.toLowerCase().contains('location') ||
            result.message.toLowerCase().contains('gps'))) {
      await _attendanceWarning(
        'Location Required',
        'Please allow location access to record attendance.',
      );
    }
    if (!mounted) return;
    setState(() {
      processing = false;
      statusMessage = result.message;
      if (result.status != 'error') {
        _pendingQrCode = null;
      }
    });
  }

  Future<void> _voidAttendance() async {
    if (_pendingQrCode == null || selectedEvent == null || processing) return;
    final reason = await _showVoidReasonDialog();
    if (reason == null || !mounted) return;

    setState(() {
      processing = true;
      statusMessage = 'Voiding attendance...';
    });

    final message = await context.read<ScannerController>().voidQr(
      qrCode: _pendingQrCode!,
      eventId: selectedEvent!.id,
      voidReason: reason.reason,
      voidNotes: reason.notes,
    );
    if (!mounted) return;
    setState(() {
      processing = false;
      statusMessage = message;
      _pendingQrCode = null;
    });
  }

  Future<_VoidReason?> _showVoidReasonDialog() {
    String? reason;
    final notes = TextEditingController();

    return showDialog<_VoidReason>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Void Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: _qrVoidReasons
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => reason = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  labelText: reason == 'Other'
                      ? 'Written explanation (required)'
                      : 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  reason == null ||
                      (reason == 'Other' && notes.text.trim().isEmpty)
                  ? null
                  : () => Navigator.pop(
                      context,
                      _VoidReason(
                        reason: reason!,
                        notes: notes.text.trim().isEmpty
                            ? null
                            : notes.text.trim(),
                      ),
                    ),
              child: const Text('Void'),
            ),
          ],
        ),
      ),
    ).whenComplete(notes.dispose);
  }

  bool _hasFaceRegistration(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['has_face_registration'] == true ||
        data['face_registered'] == true;
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

  String? _policyMessage(ScannerController scanner) {
    return scanner.qrPolicyMessage(selectedEvent);
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
        borderRadius: BorderRadius.circular(9),
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationPanel extends StatelessWidget {
  const _ConfirmationPanel({
    required this.hasFaceRegistration,
    required this.fallbackReasons,
    required this.selectedFallbackReason,
    required this.fallbackOtherController,
    required this.processing,
    required this.onFallbackChanged,
    required this.onConfirm,
    required this.onVoid,
  });

  final bool hasFaceRegistration;
  final List<String> fallbackReasons;
  final String? selectedFallbackReason;
  final TextEditingController fallbackOtherController;
  final bool processing;
  final ValueChanged<String?> onFallbackChanged;
  final VoidCallback onConfirm;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          if (hasFaceRegistration) ...[
            const Text(
              'This student already has face registration. QR attendance requires a reason.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedFallbackReason,
              decoration: const InputDecoration(
                labelText: 'QR fallback reason',
                border: OutlineInputBorder(),
              ),
              items: fallbackReasons
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: processing ? null : onFallbackChanged,
            ),
            if (selectedFallbackReason == 'other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: fallbackOtherController,
                enabled: !processing,
                decoration: const InputDecoration(
                  labelText: 'Other reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: processing ? null : onConfirm,
                  child: const Text('Confirm Present'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: processing ? null : onVoid,
                  child: const Text('Void Attendance'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoidReason {
  const _VoidReason({required this.reason, this.notes});

  final String reason;
  final String? notes;
}

class _EventSelector extends StatelessWidget {
  const _EventSelector({
    required this.events,
    required this.selectedEvent,
    required this.loading,
    required this.onChanged,
  });

  final List<EventModel> events;
  final EventModel? selectedEvent;
  final bool loading;
  final ValueChanged<EventModel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<EventModel>(
      initialValue: selectedEvent,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 26,
          vertical: 20,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      ),
      hint: Text(
        loading
            ? 'Loading events...'
            : 'No event currently open for attendance',
      ),
      items: events
          .map(
            (event) => DropdownMenuItem(
              value: event,
              child: Text(
                '${event.name} - ${event.attendancePhaseDisplay}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          )
          .toList(),
      onChanged: events.isEmpty ? null : onChanged,
    );
  }
}

class _LastScannedCard extends StatelessWidget {
  const _LastScannedCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final student = Map<String, dynamic>.from(data['student'] as Map? ?? {});
    final user = Map<String, dynamic>.from(student['user'] as Map? ?? {});
    final details = Map<String, dynamic>.from(student['details'] as Map? ?? {});
    final name = user['full_name']?.toString() ?? 'Verified student';
    final idNumber = details['idnumber']?.toString();
    final course = details['course']?.toString();
    final section =
        details['section']?.toString() ?? details['year_section']?.toString();
    final meta = [
      idNumber,
      [
        course,
        section,
      ].where((value) => value != null && value.trim().isNotEmpty).join(' - '),
    ].where((value) => value != null && value.trim().isNotEmpty).join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last scanned QR',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
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
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentDetailsCard extends StatelessWidget {
  const _StudentDetailsCard({required this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final student = Map<String, dynamic>.from(data?['student'] as Map? ?? {});
    final user = Map<String, dynamic>.from(student['user'] as Map? ?? {});
    final details = Map<String, dynamic>.from(student['details'] as Map? ?? {});
    final name = user['full_name']?.toString();
    final email = user['email']?.toString();
    final idNumber = details['idnumber']?.toString();
    final course = details['course']?.toString();
    final section =
        details['section']?.toString() ?? details['year_section']?.toString();
    // Prefer the API's normalized photo URL/data URI. The raw photo field
    // may be a storage path such as student-profiles/photo.jpg.
    final photo =
        details['photo_url']?.toString() ??
        student['profile_photo_url']?.toString() ??
        details['photo']?.toString();
    final photoProvider = _scannerPhotoProvider(photo);
    final faceRegistered =
        data?['has_face_registration'] == true ||
        data?['face_registered'] == true;
    final event = Map<String, dynamic>.from(data?['event'] as Map? ?? {});
    final eventName = event['name']?.toString();
    final attendanceStatus = data?['attendance_status']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 42),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 150,
            backgroundColor: Color(0xFFC7C7C7),
            backgroundImage: photoProvider,
            child: photoProvider == null
                ? const Icon(Icons.person, color: Colors.white, size: 180)
                : null,
          ),
          const SizedBox(height: 56),
          _DetailLine(value: name),
          _DetailLine(value: idNumber),
          _DetailLine(value: course),
          _DetailLine(value: section),
          _DetailLine(value: email),
          _DetailLine(
            value: 'Face Registered: ${faceRegistered ? 'Yes' : 'No'}',
          ),
          if (eventName != null) _DetailLine(value: 'Event: $eventName'),
          if (attendanceStatus != null)
            _DetailLine(value: 'Attendance: $attendanceStatus'),
        ],
      ),
    );
  }
}

ImageProvider? _scannerPhotoProvider(String? source) {
  final value = source?.trim();
  if (value == null || value.isEmpty || value == 'null') return null;
  if (value.startsWith('http')) return NetworkImage(value);
  try {
    final encoded = value.contains(',') ? value.split(',').last : value;
    return MemoryImage(base64Decode(encoded));
  } catch (_) {
    return null;
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Text(
        text == null || text.isEmpty ? '---' : text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }
}
