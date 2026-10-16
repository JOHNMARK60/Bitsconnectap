import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/utils/date_formatter.dart';
import 'package:bits_mobile_app/core/widgets/app_button.dart';
import 'package:bits_mobile_app/core/widgets/app_card.dart';
import 'package:bits_mobile_app/screens/scanner/widgets/scanner_logout_button.dart';
import 'package:flutter/material.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({required this.result, super.key});

  final Map<String, dynamic>? result;

  @override
  Widget build(BuildContext context) {
    final data = result ?? {};
    final isError = data['status'] == 'error';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        actions: const [ScannerLogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  size: 64,
                  color: isError ? AppColors.danger : AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  data['message']?.toString() ?? 'Scan processed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                if (data['student_name'] != null)
                  Text('Student: ${data['student_name']}'),
                if (data['event_name'] != null)
                  Text('Event: ${data['event_name']}'),
                if (data['scan_time'] != null)
                  Text(
                    'Time: ${DateFormatter.dateTime(data['scan_time'].toString())}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Scan Again',
            icon: Icons.qr_code_scanner,
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.scannerQr),
          ),
        ],
      ),
    );
  }
}
