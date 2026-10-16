import 'dart:async';

import 'package:bits_mobile_app/app/app.dart';
import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/alumni_controller.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/scanner_controller.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/controllers/theme_controller.dart';
import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/core/services/app_update_service.dart';
import 'package:bits_mobile_app/core/services/auth_service.dart';
import 'package:bits_mobile_app/core/services/location_service.dart';
import 'package:bits_mobile_app/core/services/mobile_notification_service.dart';
import 'package:bits_mobile_app/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureStorageService();
  final api = ApiService(storage);
  final authService = AuthService(api, storage);
  final locationService = LocationService();
  final notificationService = MobileNotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(authService)),
        ChangeNotifierProvider(create: (_) => ThemeController(storage)..load()),
        ChangeNotifierProvider(
          create: (_) => StudentController(api, notificationService, storage),
        ),
        ChangeNotifierProvider(create: (_) => AlumniController(api)),
        ChangeNotifierProvider(
          create: (_) => ScannerController(api, locationService),
        ),
      ],
      child: const BitsMobileApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_checkForUpdate(AppUpdateService(api)));
  });
}

Future<void> _checkForUpdate(AppUpdateService updateService) async {
  final update = await updateService.checkForUpdate();
  final context = AppNavigator.key.currentContext;
  if (update == null || context == null) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: !update.required,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Update available'),
      content: Text(
        update.message?.isNotEmpty == true
            ? update.message!
            : 'Version ${update.latestVersion} is available. Update now for the latest improvements.',
      ),
      actions: [
        if (!update.required)
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Later'),
          ),
        FilledButton(
          onPressed: () async {
            await updateService.openUpdate(update);
          },
          child: const Text('Update now'),
        ),
      ],
    ),
  );
}
