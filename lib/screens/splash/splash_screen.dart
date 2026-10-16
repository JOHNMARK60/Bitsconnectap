import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/core/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_boot);
  }

  Future<void> _boot() async {
    final auth = context.read<AuthController>();
    final student = context.read<StudentController>();
    final navigator = Navigator.of(context);
    await auth.bootstrap();
    if (!mounted) return;
    final user = auth.user;
    var route = user == null
        ? AppRoutes.landing
        : user.isStudent
        ? AppRoutes.studentDashboard
        : user.isAlumni
        ? AppRoutes.alumniDashboard
        : AppRoutes.scannerDashboard;
    if (user != null && user.isStudent) {
      await student.loadFaceStatus();
      if (!mounted) return;
      if (student.faceRegistered != true) {
        route = AppRoutes.studentFaceRegistration;
      }
    }
    navigator.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(size: 72, borderWidth: 3),
            SizedBox(height: 18),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
