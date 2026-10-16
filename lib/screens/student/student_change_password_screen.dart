import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/screens/student/student_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentChangePasswordScreen extends StatefulWidget {
  const StudentChangePasswordScreen({super.key});

  @override
  State<StudentChangePasswordScreen> createState() =>
      _StudentChangePasswordScreenState();
}

class _StudentChangePasswordScreenState
    extends State<StudentChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StudentChrome(
      currentRoute: AppRoutes.studentChangePassword,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(36, 50, 36, 36),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(48, 50, 48, 48),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings, color: Color(0xFFB8A7D9), size: 44),
                    SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 34),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.key, color: Color(0xFFF6B21A), size: 30),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Change Password',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _PasswordField(
                          label: 'Current Password',
                          controller: _current,
                        ),
                        const SizedBox(height: 22),
                        _PasswordField(
                          label: 'New Password',
                          controller: _password,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'New password is required.';
                            }
                            if (value.length < 8) {
                              return 'New password must be at least 8 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        _PasswordField(
                          label: 'Confirm New Password',
                          controller: _confirmation,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm your new password.';
                            }
                            if (value != _password.text) {
                              return 'Password confirmation does not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(64),
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: _loading ? null : _submit,
                          child: Text(
                            _loading ? 'Changing...' : 'Change Password',
                          ),
                        ),
                      ],
                    ),
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final message = await context.read<StudentController>().changePassword(
      _current.text,
      _password.text,
      _confirmation.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Password changed successfully.')),
    );
    if ((message ?? '').toLowerCase().contains('success')) {
      _current.clear();
      _password.clear();
      _confirmation.clear();
    }
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator:
          validator ??
          (value) =>
              value == null || value.isEmpty ? '$label is required.' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 22,
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111827)
            : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
