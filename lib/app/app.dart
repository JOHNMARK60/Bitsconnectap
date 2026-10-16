import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/app/theme.dart';
import 'package:bits_mobile_app/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BitsMobileApp extends StatelessWidget {
  const BitsMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return MaterialApp(
      navigatorKey: AppNavigator.key,
      title: 'BITSConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.darkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
