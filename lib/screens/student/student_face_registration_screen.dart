import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/widgets/face_liveness_capture.dart';
import 'package:bits_mobile_app/core/widgets/error_view.dart';
import 'package:bits_mobile_app/core/widgets/loading_view.dart';
import 'package:bits_mobile_app/screens/student/student_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentFaceRegistrationScreen extends StatefulWidget {
  const StudentFaceRegistrationScreen({super.key});

  @override
  State<StudentFaceRegistrationScreen> createState() =>
      _StudentFaceRegistrationScreenState();
}

class _StudentFaceRegistrationScreenState
    extends State<StudentFaceRegistrationScreen> {
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StudentController>().loadFaceStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentController>();
    final registrationBlockedByDevice = controller.newDeviceDetected;
    final hasBackendRegistration =
        controller.faceRegistered == true || controller.backendFaceRegistered;

    return StudentChrome(
      currentRoute: AppRoutes.studentFaceRegistration,
      onRefresh: controller.loadFaceStatus,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(36, 82, 36, 36),
        children: [
          if (controller.loading && controller.faceRegistered == null)
            const SizedBox(height: 480, child: LoadingView())
          else if (controller.error != null &&
              controller.faceRegistered == null)
            ErrorView(
              message: controller.error!,
              onRetry: controller.loadFaceStatus,
            )
          else ...[
            const Text(
              'Face Registration',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'Register your face for secure authentication.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 28,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 42),
            Center(
              child: Text(
                'Face Registration: ${registrationBlockedByDevice
                    ? 'Blocked'
                    : hasBackendRegistration
                    ? 'Yes'
                    : 'No'}',
                style: TextStyle(
                  color: registrationBlockedByDevice
                      ? const Color(0xFFB45309)
                      : hasBackendRegistration
                      ? AppColors.success
                      : AppColors.danger,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (controller.newDeviceDetected &&
                (controller.faceStatusMessage ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  controller.faceStatusMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(48, 54, 48, 54),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    hasBackendRegistration
                        ? Icons.verified_user
                        : Icons.photo_camera,
                    color: const Color(0xFF9CA3AF),
                    size: 96,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    registrationBlockedByDevice
                        ? 'Face registration is locked for this account.'
                        : hasBackendRegistration
                        ? 'Face registration is complete.'
                        : 'Click the button below to start scanning.',
                    style: const TextStyle(fontSize: 28, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(376, 64),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed:
                    _uploading ||
                        hasBackendRegistration ||
                        registrationBlockedByDevice
                    ? null
                    : _openCamera,
                icon: _uploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1, size: 30),
                label: Text(_uploading ? 'Uploading...' : 'Register Face'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCamera() async {
    try {
      final image = await FaceLivenessCapture.capture(
        context,
        title: 'Face Registration',
      );
      if (image == null || !mounted) return;

      setState(() => _uploading = true);
      final user = context.read<AuthController>().user;
      final message = await context.read<StudentController>().registerFaceImage(
        image: image,
        studentId: user?.id ?? 0,
        livenessDetected: true,
      );
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Face registered successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to register face. Please retry.')),
      );
    }
  }
}
