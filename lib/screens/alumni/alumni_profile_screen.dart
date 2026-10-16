import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/alumni_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlumniProfileScreen extends StatefulWidget {
  const AlumniProfileScreen({super.key});

  @override
  State<AlumniProfileScreen> createState() => _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends State<AlumniProfileScreen> {
  final fields = <String, TextEditingController>{};
  var selectedTab = 0;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    for (final key in _fieldKeys) {
      fields[key] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AlumniController>().loadProfile();
      if (mounted) _fillFields();
    });
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AlumniController>();
    final user = Map<String, dynamic>.from(
      controller.profile?['user'] as Map? ?? {},
    );
    final details = Map<String, dynamic>.from(
      controller.profile?['details'] as Map? ?? {},
    );
    final completion = _completion(user, details);

    return AlumniModuleChrome(
      title: 'Alumni Portal',
      selectedRoute: AppRoutes.alumniProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 54, 22, 30),
        children: [
          const Text(
            'ALUMNI PORTAL',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Profile Information',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep your alumni record current for yearbook, events, and verification.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 20,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          _StatusPill(completion: completion),
          const SizedBox(height: 24),
          if (controller.loading && controller.profile == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (controller.error != null && controller.profile == null)
            _ProfileCard(
              child: Column(
                children: [
                  Text(controller.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: controller.loadProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else ...[
            _SummaryCard(user: user, details: details, completion: completion),
            const SizedBox(height: 24),
            _ProfileCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _TabChip(
                          'Account',
                          selected: selectedTab == 0,
                          onTap: () => setState(() => selectedTab = 0),
                        ),
                        _TabChip(
                          'Academic',
                          selected: selectedTab == 1,
                          onTap: () => setState(() => selectedTab = 1),
                        ),
                        _TabChip(
                          'Personal & Photo',
                          selected: selectedTab == 2,
                          onTap: () => setState(() => selectedTab = 2),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFDCE5F0)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tabTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tabSubtitle,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 18,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 26),
                        for (final item in _activeFields)
                          _ProfileField(
                            label: item.$1,
                            controller: fields[item.$2]!,
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFDCE5F0)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete each section before saving.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: AppColors.primary,
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          onPressed: saving ? null : _save,
                          child: Text(
                            saving ? 'Updating...' : 'Update Profile',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _fillFields() {
    final profile = context.read<AlumniController>().profile;
    final user = Map<String, dynamic>.from(profile?['user'] as Map? ?? {});
    final details = Map<String, dynamic>.from(
      profile?['details'] as Map? ?? {},
    );
    final fullName = (user['full_name']?.toString() ?? 'Alumni User').split(
      RegExp(r'\s+'),
    );
    fields['first_name']!.text =
        user['first_name']?.toString() ??
        (fullName.isNotEmpty ? fullName.first : '');
    fields['last_name']!.text =
        user['last_name']?.toString() ??
        (fullName.length > 1 ? fullName.last : '');
    fields['middle_name']!.text = details['middle_name']?.toString() ?? 'n/a';
    fields['dob']!.text = details['dob']?.toString() ?? '';
    fields['email']!.text = user['email']?.toString() ?? '';
    fields['idnumber']!.text = details['idnumber']?.toString() ?? '';
    fields['course']!.text = details['course']?.toString() ?? '';
    fields['academic_year']!.text = details['academic_year']?.toString() ?? '';
    fields['gender']!.text = details['gender']?.toString() ?? '';
    fields['birthplace']!.text = details['birthplace']?.toString() ?? '';
    fields['address']!.text = details['address']?.toString() ?? '';
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final message = await context.read<AlumniController>().updateProfile({
      for (final entry in fields.entries) entry.key: entry.value.text,
    });
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Profile updated.')));
  }

  String get _tabTitle => switch (selectedTab) {
    0 => 'Account Details',
    1 => 'Academic Details',
    _ => 'Personal Details',
  };

  String get _tabSubtitle => switch (selectedTab) {
    0 => 'Basic information connected to your alumni account.',
    1 => 'Academic record used across alumni services.',
    _ => 'Personal details used for verification.',
  };

  List<(String, String)> get _activeFields => switch (selectedTab) {
    0 => const [
      ('FIRST NAME', 'first_name'),
      ('LAST NAME', 'last_name'),
      ('MIDDLE NAME', 'middle_name'),
      ('DATE OF BIRTH', 'dob'),
      ('EMAIL', 'email'),
    ],
    1 => const [
      ('ID NUMBER', 'idnumber'),
      ('COURSE', 'course'),
      ('ACADEMIC YEAR', 'academic_year'),
    ],
    _ => const [
      ('GENDER', 'gender'),
      ('BIRTHPLACE', 'birthplace'),
      ('ADDRESS', 'address'),
    ],
  };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.user,
    required this.details,
    required this.completion,
  });

  final Map<String, dynamic> user;
  final Map<String, dynamic> details;
  final int completion;

  @override
  Widget build(BuildContext context) {
    final name = user['full_name']?.toString() ?? 'Alumni User';
    final email = user['email']?.toString() ?? 'alumni@example.com';
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 106,
            height: 106,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: Text(
              _initial(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: const TextStyle(color: AppColors.muted, fontSize: 17),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Profile completion',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const Spacer(),
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
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MiniInfo('ID NUMBER', details['idnumber']?.toString()),
          _MiniInfo('COURSE', details['course']?.toString()),
          _MiniInfo('ACADEMIC YEAR', details['academic_year']?.toString()),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.child,
    this.padding = const EdgeInsets.all(28),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5F0)),
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.completion});

  final int completion;

  @override
  Widget build(BuildContext context) {
    final complete = completion >= 100;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: complete ? const Color(0xFFDDFBEA) : const Color(0xFFDFF4FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          complete ? 'Complete' : 'Needs update',
          style: TextStyle(
            color: complete ? const Color(0xFF047857) : const Color(0xFF075985),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text == null || text.isEmpty ? 'Not set' : text,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip(this.label, {required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.muted,
        fontWeight: FontWeight.w900,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF0F5FB),
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

const _fieldKeys = [
  'first_name',
  'last_name',
  'middle_name',
  'dob',
  'email',
  'idnumber',
  'course',
  'academic_year',
  'gender',
  'birthplace',
  'address',
];

int _completion(Map<String, dynamic> user, Map<String, dynamic> details) {
  final values = [
    user['full_name'],
    user['email'],
    details['idnumber'],
    details['course'],
    details['academic_year'],
    details['gender'],
    details['address'],
  ];
  final filled = values
      .where((value) => (value?.toString().trim() ?? '').isNotEmpty)
      .length;
  return ((filled / values.length) * 100).round();
}

String _initial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? 'A' : trimmed.characters.first.toUpperCase();
}
