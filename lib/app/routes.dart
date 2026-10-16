import 'package:bits_mobile_app/screens/alumni/alumni_change_password_screen.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_dashboard_screen.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_events_screen.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_profile_screen.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_records_screen.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_yearbook_screen.dart';
import 'package:bits_mobile_app/screens/auth/login_screen.dart';
import 'package:bits_mobile_app/screens/landing/landing_screen.dart';
import 'package:bits_mobile_app/screens/scanner/face_attendance_scanner_screen.dart';
import 'package:bits_mobile_app/screens/scanner/qr_scanner_screen.dart';
import 'package:bits_mobile_app/screens/scanner/scan_history_screen.dart';
import 'package:bits_mobile_app/screens/scanner/scan_result_screen.dart';
import 'package:bits_mobile_app/screens/scanner/scanner_dashboard_screen.dart';
import 'package:bits_mobile_app/screens/scanner/scanner_events_screen.dart';
import 'package:bits_mobile_app/screens/scanner/scanner_face_registration_screen.dart';
import 'package:bits_mobile_app/screens/splash/splash_screen.dart';
import 'package:bits_mobile_app/screens/student/student_attended_events_screen.dart';
import 'package:bits_mobile_app/screens/student/student_face_attendance_screen.dart';
import 'package:bits_mobile_app/screens/student/student_change_password_screen.dart';
import 'package:bits_mobile_app/screens/student/student_dashboard_screen.dart';
import 'package:bits_mobile_app/screens/student/student_events_screen.dart';
import 'package:bits_mobile_app/screens/student/student_face_registration_screen.dart';
import 'package:bits_mobile_app/screens/student/student_profile_screen.dart';
import 'package:flutter/material.dart';

class AppNavigator {
  static final key = GlobalKey<NavigatorState>();
}

class AppRoutes {
  static const landing = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const portalLogin = '/portal-login';
  static const studentDashboard = '/student';
  static const studentProfile = '/student/profile';
  static const studentEvents = '/student/events';
  static const studentAttendedEvents = '/student/attended-events';
  static const studentChangePassword = '/student/change-password';
  static const studentFaceRegistration = '/student/face-registration';
  static const studentFaceAttendance = '/student/face-attendance';
  static const alumniDashboard = '/alumni';
  static const alumniProfile = '/alumni/profile';
  static const alumniRecords = '/alumni/records';
  static const alumniYearbook = '/alumni/yearbook';
  static const alumniEvents = '/alumni/events';
  static const alumniChangePassword = '/alumni/change-password';
  static const scannerDashboard = '/scanner';
  static const scannerEvents = '/scanner/events';
  static const scannerQr = '/scanner/qr';
  static const scannerFaceAttendance = '/scanner/face-attendance';
  static const scannerFaceRegistration = '/scanner/face-registration';
  static const scannerResult = '/scanner/result';
  static const scannerHistory = '/scanner/history';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routes = <String, WidgetBuilder>{
      landing: (_) => const LandingScreen(),
      splash: (_) => const SplashScreen(),
      login: (_) => const LandingScreen(),
      portalLogin: (_) => const LoginScreen(),
      studentDashboard: (_) => const StudentDashboardScreen(),
      studentProfile: (_) => const StudentProfileScreen(),
      studentEvents: (_) => const StudentEventsScreen(),
      studentAttendedEvents: (_) => const StudentAttendedEventsScreen(),
      studentChangePassword: (_) => const StudentChangePasswordScreen(),
      studentFaceRegistration: (_) => const StudentFaceRegistrationScreen(),
      studentFaceAttendance: (_) => const StudentFaceAttendanceScreen(),
      alumniDashboard: (_) => const AlumniDashboardScreen(),
      alumniProfile: (_) => const AlumniProfileScreen(),
      alumniRecords: (_) => const AlumniRecordsScreen(),
      alumniYearbook: (_) => const AlumniYearbookScreen(),
      alumniEvents: (_) => const AlumniEventsScreen(),
      alumniChangePassword: (_) => const AlumniChangePasswordScreen(),
      scannerDashboard: (_) => const ScannerDashboardScreen(),
      scannerEvents: (_) => const ScannerEventsScreen(),
      scannerQr: (_) => const QrScannerScreen(),
      scannerFaceAttendance: (_) => const FaceAttendanceScannerScreen(),
      scannerFaceRegistration: (_) => const ScannerFaceRegistrationScreen(),
      scannerResult: (_) =>
          ScanResultScreen(result: settings.arguments as Map<String, dynamic>?),
      scannerHistory: (_) => const ScanHistoryScreen(),
    };

    return MaterialPageRoute(
      builder: routes[settings.name] ?? (_) => const LandingScreen(),
      settings: settings,
    );
  }
}
