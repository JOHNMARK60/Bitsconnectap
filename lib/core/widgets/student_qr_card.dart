import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/utils/qr_code_file.dart';
import 'package:bits_mobile_app/core/widgets/app_button.dart';
import 'package:bits_mobile_app/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentQrCard extends StatefulWidget {
  const StudentQrCard({required this.qrCode, super.key});

  final String? qrCode;

  @override
  State<StudentQrCard> createState() => _StudentQrCardState();
}

class _StudentQrCardState extends State<StudentQrCard> {
  bool _saving = false;

  bool get _hasQr => widget.qrCode != null && widget.qrCode!.trim().isNotEmpty;

  Future<void> _downloadQr() async {
    if (!_hasQr || _saving) return;

    setState(() => _saving = true);
    try {
      await saveQrCodePng(widget.qrCode!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code downloaded successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to download QR code. Please check storage permission and try again.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Student QR Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              if (_hasQr)
                const Icon(Icons.verified_outlined, color: AppColors.teal),
            ],
          ),
          const SizedBox(height: 14),
          if (_hasQr) ...[
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showQrCodePreview(context, widget.qrCode!),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(18),
                  child: QrImageView(
                    data: widget.qrCode!,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.qrCode!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Download QR Code',
              icon: Icons.download_outlined,
              loading: _saving,
              onPressed: _downloadQr,
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'QR Code not generated yet.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
