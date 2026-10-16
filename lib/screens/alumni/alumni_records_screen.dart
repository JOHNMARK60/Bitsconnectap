import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/alumni_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlumniRecordsScreen extends StatefulWidget {
  const AlumniRecordsScreen({super.key});

  @override
  State<AlumniRecordsScreen> createState() => _AlumniRecordsScreenState();
}

class _AlumniRecordsScreenState extends State<AlumniRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AlumniController>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AlumniController>();
    final records = (controller.records?['work_experiences'] as List?) ?? [];
    return AlumniModuleChrome(
      title: 'Work\nExperience',
      selectedRoute: AppRoutes.alumniRecords,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(84, 145, 84, 32),
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(76),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            onPressed: () => _showWorkForm(context),
            icon: const Icon(Icons.add_circle, size: 34),
            label: const Text('Add Work Experience'),
          ),
          const SizedBox(height: 32),
          if (controller.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (controller.error != null)
            _StateCard(
              message: controller.error!,
              onRetry: controller.loadRecords,
            )
          else if (records.isEmpty)
            const _EmptyWorkCard()
          else
            ...records.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WorkCard(
                  item: item,
                  onEdit: () => _showWorkForm(context, item),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showWorkForm(
    BuildContext context, [
    Map<String, dynamic>? item,
  ]) async {
    final company = TextEditingController(
      text: item?['company_name']?.toString() ?? '',
    );
    final position = TextEditingController(
      text: item?['position']?.toString() ?? '',
    );
    final description = TextEditingController(
      text: item?['description']?.toString() ?? '',
    );
    final start = TextEditingController(
      text: item?['start_date']?.toString() ?? '',
    );
    final end = TextEditingController(
      text: item?['end_date']?.toString() ?? '',
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Work Experience',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _Field(controller: company, label: 'Company name'),
            _Field(controller: position, label: 'Position'),
            _Field(controller: start, label: 'Start date'),
            _Field(controller: end, label: 'End date'),
            _Field(controller: description, label: 'Description', maxLines: 3),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save Work Experience'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;
    final message = await context.read<AlumniController>().saveWorkExperience(
      id: int.tryParse(item?['id']?.toString() ?? ''),
      data: {
        'company_name': company.text,
        'position': position.text,
        'start_date': start.text,
        'end_date': end.text,
        'description': description.text,
      },
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message ?? 'Saved.')));
    }
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.item, required this.onEdit});

  final Map<String, dynamic> item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE5F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.work_outline, color: AppColors.primary, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['position']?.toString() ?? 'Position',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(item['company_name']?.toString() ?? 'Company'),
                if ((item['contact_number']?.toString() ?? '').isNotEmpty)
                  Text(
                    'Contact: ${item['contact_number']}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                if ((item['description']?.toString() ?? '').isNotEmpty)
                  Text(
                    item['description'].toString(),
                    style: const TextStyle(color: AppColors.muted),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () async {
              final id = int.tryParse(item['id']?.toString() ?? '');
              if (id == null) return;
              final message = await context
                  .read<AlumniController>()
                  .deleteWorkExperience(id);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message ?? 'Deleted.')));
              }
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkCard extends StatelessWidget {
  const _EmptyWorkCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Text(
        'No work experiences\nfound.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 34, color: Colors.grey, height: 1.15),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
