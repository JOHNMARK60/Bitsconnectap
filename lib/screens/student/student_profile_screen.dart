import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/student_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/widgets/error_view.dart';
import 'package:bits_mobile_app/core/widgets/loading_view.dart';
import 'package:bits_mobile_app/models/user_model.dart';
import 'package:bits_mobile_app/screens/student/student_module_chrome.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  int _tab = 0;
  bool _uploadingPhoto = false;
  final _fields = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<StudentController>().loadProfile();
      if (mounted) _syncFields();
    });
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentController>();
    final authUser = context.watch<AuthController>().user;
    final profile = Map<String, dynamic>.from(controller.profile ?? {});
    final user = Map<String, dynamic>.from(profile['user'] as Map? ?? {});
    final details = Map<String, dynamic>.from(profile['details'] as Map? ?? {});
    final fullName = _first([
      displayName(user, fallback: ''),
      user['full_name'],
      user['name'],
      user['student_name'],
      authUser?.fullName,
      'Student',
    ]);
    final email = _first([user['email'], authUser?.email, '']);
    final completion = _completion(user, details);
    final locked = completion >= 100;
    final photo = _first([
      details['photo_url'],
      profile['profile_photo_url'],
      details['photo'],
    ]);

    return StudentChrome(
      currentRoute: AppRoutes.studentProfile,
      onRefresh: () async {
        await controller.loadProfile();
        _syncFields();
      },
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 38, 22, 36),
        children: [
          if (controller.loading && controller.profile == null)
            const SizedBox(height: 520, child: LoadingView())
          else if (controller.error != null && controller.profile == null)
            ErrorView(
              message: controller.error!,
              onRetry: controller.loadProfile,
            )
          else ...[
            const Text(
              'STUDENT PORTAL',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep your student record updated for attendance, QR verification, and campus events.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 18,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(complete: locked),
            ),
            const SizedBox(height: 26),
            _ProfileHeader(
              name: fullName,
              email: email,
              details: details,
              completion: completion,
              photo: photo,
              uploadingPhoto: _uploadingPhoto,
              onUploadPhoto: _pickProfilePhoto,
            ),
            const SizedBox(height: 24),
            _DetailsPanel(
              tab: _tab,
              locked: locked,
              fields: _fields,
              onTab: (value) => setState(() => _tab = value),
              onSave: () => _saveProfile(context),
            ),
          ],
        ],
      ),
    );
  }

  TextEditingController _field(String key) {
    return _fields.putIfAbsent(key, TextEditingController.new);
  }

  void _syncFields() {
    final profile = context.read<StudentController>().profile;
    final user = Map<String, dynamic>.from((profile?['user'] as Map?) ?? {});
    final details = Map<String, dynamic>.from(
      (profile?['details'] as Map?) ?? {},
    );
    final values = {
      'firstname': user['firstname'] ?? user['first_name'],
      'lastname': user['lastname'] ?? user['last_name'],
      'middlename': user['middlename'],
      'dateofbirth': user['dateofbirth'],
      'email': user['email'],
      'idnumber': details['idnumber'],
      'course': details['course'],
      'year': details['year'],
      'section': details['section'],
      'semester': details['semester'],
      'academic_year': details['academic_year'],
      'birthplace': details['birthplace'],
      'address': details['address'],
      'gender': details['gender'],
    };
    for (final entry in values.entries) {
      _field(entry.key).text = entry.value?.toString() ?? '';
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    final message = await context.read<StudentController>().updateProfile({
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Profile saved.')));
  }

  Future<void> _pickProfilePhoto() async {
    if (_uploadingPhoto) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (image == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final message = await context.read<StudentController>().uploadProfilePhoto(
      image,
    );
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Profile photo saved.')));
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: complete ? const Color(0xFFDDFBE8) : const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        complete ? 'Complete' : 'Needs Update',
        style: TextStyle(
          color: complete ? const Color(0xFF047857) : AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.details,
    required this.completion,
    required this.photo,
    required this.uploadingPhoto,
    required this.onUploadPhoto,
  });

  final String name;
  final String email;
  final Map<String, dynamic> details;
  final int completion;
  final String photo;
  final bool uploadingPhoto;
  final VoidCallback onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentAvatar(name: name, photo: photo, size: 104),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: uploadingPhoto ? null : onUploadPhoto,
            icon: uploadingPhoto
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_outlined),
            label: Text(
              uploadingPhoto ? 'Uploading...' : 'Upload profile photo',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: const TextStyle(color: AppColors.muted, fontSize: 17),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Profile completion')),
                    Text(
                      '$completion%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: completion / 100,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.primary,
                  backgroundColor: const Color(0xFFE0F2FE),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InfoBox('ID Number', _first([details['idnumber'], 'Not set'])),
          _InfoBox('Course', _first([details['course'], 'Not set'])),
          _InfoBox(
            'Year / Section',
            '${_first([details['year'], '-'])} / ${_first([details['section'], '-'])}',
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.tab,
    required this.locked,
    required this.fields,
    required this.onTab,
    required this.onSave,
  });

  final int tab;
  final bool locked;
  final Map<String, TextEditingController> fields;
  final ValueChanged<int> onTab;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TabChip('Account', 0, tab, onTab),
                _TabChip('Academic', 1, tab, onTab),
                _TabChip('Personal & Photo', 2, tab, onTab),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab == 0
                      ? 'Account Details'
                      : tab == 1
                      ? 'Academic Details'
                      : 'Personal Details',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  locked
                      ? 'Your profile is locked after completion.'
                      : 'Update missing profile information.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 16),
                ),
                const SizedBox(height: 22),
                if (tab == 0) ...[
                  _ReadField('First Name', fields['firstname']!, locked),
                  _ReadField('Last Name', fields['lastname']!, locked),
                  _ReadField('Middle Name', fields['middlename']!, locked),
                  _ReadField('Date of Birth', fields['dateofbirth']!, locked),
                  _ReadField('Email', fields['email']!, locked),
                  _ReadField('ID Number', fields['idnumber']!, locked),
                ] else if (tab == 1) ...[
                  _ReadField('Course', fields['course']!, locked),
                  _ReadField('Year', fields['year']!, locked),
                  _ReadField('Section', fields['section']!, locked),
                  _ReadField('Semester', fields['semester']!, locked),
                  _ReadField('Academic Year', fields['academic_year']!, locked),
                ] else ...[
                  _ReadField('Gender', fields['gender']!, locked),
                  _ReadField('Birthplace', fields['birthplace']!, locked),
                  _ReadField(
                    'Address',
                    fields['address']!,
                    locked,
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(28),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: locked ? null : onSave,
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip(this.label, this.value, this.selected, this.onTap);

  final String label;
  final int value;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return ChoiceChip(
      selected: active,
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        color: active ? Colors.white : AppColors.muted,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
      selectedColor: AppColors.royal,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onSelected: (_) => onTap(value),
    );
  }
}

class _ReadField extends StatelessWidget {
  const _ReadField(
    this.label,
    this.controller,
    this.locked, {
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool locked;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        enabled: !locked,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(28)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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
      child: child,
    );
  }
}

int _completion(Map<String, dynamic> user, Map<String, dynamic> details) {
  final values = [
    user['firstname'] ?? user['first_name'],
    user['lastname'] ?? user['last_name'],
    user['email'],
    user['dateofbirth'],
    details['idnumber'],
    details['course'],
    details['year'],
    details['section'],
    details['gender'],
    details['semester'],
    details['academic_year'],
    details['birthplace'],
    details['address'],
    details['photo'],
  ];
  final filled = values
      .where((value) => value != null && value.toString().trim().isNotEmpty)
      .length;
  return ((filled / values.length) * 100).round();
}

String _first(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') return text;
  }
  return '';
}
