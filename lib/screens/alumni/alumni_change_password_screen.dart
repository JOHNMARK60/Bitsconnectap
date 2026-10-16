import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/alumni_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlumniChangePasswordScreen extends StatefulWidget {
  const AlumniChangePasswordScreen({super.key});

  @override
  State<AlumniChangePasswordScreen> createState() =>
      _AlumniChangePasswordScreenState();
}

class _AlumniChangePasswordScreenState
    extends State<AlumniChangePasswordScreen> {
  final current = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlumniModuleChrome(
      title: 'Settings',
      selectedRoute: AppRoutes.alumniChangePassword,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(36, 50, 36, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE5F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings, color: Color(0xFFB7A0D7), size: 40),
                    SizedBox(width: 14),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.key, color: AppColors.warning, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        label: 'Current Password',
                        controller: current,
                      ),
                      _PasswordField(
                        label: 'New Password',
                        controller: password,
                      ),
                      _PasswordField(
                        label: 'Confirm New Password',
                        controller: confirmation,
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          minimumSize: const Size.fromHeight(70),
                          textStyle: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: saving ? null : _submit,
                        child: Text(saving ? 'Changing...' : 'Change Password'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => saving = true);
    final message = await context.read<AlumniController>().changePassword(
      current.text,
      password.text,
      confirmation.text,
    );
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Password updated.')));
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
