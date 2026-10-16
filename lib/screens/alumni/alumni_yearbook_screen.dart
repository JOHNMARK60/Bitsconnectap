import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/alumni_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AlumniYearbookScreen extends StatefulWidget {
  const AlumniYearbookScreen({super.key});

  @override
  State<AlumniYearbookScreen> createState() => _AlumniYearbookScreenState();
}

class _AlumniYearbookScreenState extends State<AlumniYearbookScreen> {
  final motto = TextEditingController();
  final graduationYear = TextEditingController();
  XFile? image;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AlumniController>().loadRecords();
    });
  }

  @override
  void dispose() {
    motto.dispose();
    graduationYear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yearbook = Map<String, dynamic>.from(
      context.watch<AlumniController>().records?['yearbook'] as Map? ?? {},
    );
    if (motto.text.isEmpty && yearbook['motto'] != null) {
      motto.text = yearbook['motto'].toString();
    }
    if (graduationYear.text.isEmpty && yearbook['grad_year'] != null) {
      graduationYear.text = yearbook['grad_year'].toString();
    }

    return AlumniModuleChrome(
      title: 'Yearbook\nInformation',
      selectedRoute: AppRoutes.alumniYearbook,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(84, 194, 84, 36),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 56),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE5F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (yearbook.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(34),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFE49C)),
                    ),
                    child: const Text(
                      'Sorry, you haven\'t uploaded your graduation picture yet. Please upload it below.',
                      style: TextStyle(
                        fontSize: 27,
                        height: 1.45,
                        color: Color(0xFF8A6500),
                      ),
                    ),
                  ),
                const SizedBox(height: 34),
                const _Label('Graduation Picture'),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) setState(() => image = picked);
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(image == null ? 'Choose File' : image!.name),
                ),
                const SizedBox(height: 28),
                const _Label('Motto'),
                TextField(
                  controller: motto,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),
                const _Label('Graduation Year'),
                TextField(
                  controller: graduationYear,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'yyyy-mm-dd',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(332, 76),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: saving ? null : () => _submit(context),
                    child: Text(saving ? 'Submitting...' : 'Submit Yearbook'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a graduation picture first.')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final alumni = context.read<AlumniController>();
    setState(() => saving = true);
    final message = await alumni.submitYearbook(
      image: image!,
      motto: motto.text,
      graduationYear: graduationYear.text,
    );
    if (!mounted) return;
    setState(() => saving = false);
    messenger.showSnackBar(
      SnackBar(content: Text(message ?? 'Yearbook submitted.')),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w500),
      ),
    );
  }
}
