import 'package:bits_mobile_app/controllers/scanner_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/widgets/face_liveness_capture.dart';
import 'package:bits_mobile_app/screens/scanner/widgets/scanner_logout_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScannerFaceRegistrationScreen extends StatefulWidget {
  const ScannerFaceRegistrationScreen({super.key});

  @override
  State<ScannerFaceRegistrationScreen> createState() =>
      _ScannerFaceRegistrationScreenState();
}

class _ScannerFaceRegistrationScreenState
    extends State<ScannerFaceRegistrationScreen> {
  final searchController = TextEditingController();
  int? selectedStudentId;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ScannerController>().loadStudents();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerController>();
    final query = searchController.text.trim().toLowerCase();
    final visibleStudents = scanner.students.where((student) {
      final id = int.tryParse(student['id']?.toString() ?? '');
      final searchable = [
        student['name'],
        student['student_id'],
        student['course'],
        student['section'],
      ].whereType<Object>().join(' ').toLowerCase();
      return query.isEmpty ||
          searchable.contains(query) ||
          id == selectedStudentId;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register Student Face'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: const [ScannerLogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          const Text(
            'Register Student Face',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a student and capture only that student’s face. This enrolls a face embedding; it does not train a new AI model.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 17,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: searchController,
            enabled: !uploading,
            decoration: const InputDecoration(
              labelText: 'Search students',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: selectedStudentId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Student',
              border: OutlineInputBorder(),
            ),
            items: visibleStudents.map((student) {
              final id = int.tryParse(student['id']?.toString() ?? '') ?? 0;
              final registered = student['face_registered'] == true;
              final studentNumber = student['student_id']?.toString() ?? '';
              final label = [
                student['name']?.toString() ?? 'Student',
                if (studentNumber.isNotEmpty) studentNumber,
                if (registered) 'Registered',
              ].join(' • ');
              return DropdownMenuItem<int>(
                value: id,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: uploading
                ? null
                : (value) => setState(() => selectedStudentId = value),
          ),
          if (scanner.loading && scanner.students.isEmpty) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
          if (scanner.error != null && scanner.students.isEmpty) ...[
            const SizedBox(height: 18),
            Text(
              scanner.error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: AppColors.primary,
            ),
            onPressed: uploading ? null : _register,
            icon: uploading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: Text(uploading ? 'Uploading...' : 'Capture Student Face'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    final studentId = selectedStudentId;
    if (studentId == null) {
      _message('Select a student first.');
      return;
    }

    final image = await FaceLivenessCapture.capture(
      context,
      title: 'Face Registration',
    );
    if (image == null || !mounted) return;

    setState(() => uploading = true);
    final message = await context.read<ScannerController>().registerStudentFace(
      studentId,
      image,
    );
    if (!mounted) return;
    setState(() => uploading = false);
    _message(message);
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
