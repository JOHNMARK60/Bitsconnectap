import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/alumni_controller.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlumniDashboardScreen extends StatefulWidget {
  const AlumniDashboardScreen({super.key});

  @override
  State<AlumniDashboardScreen> createState() => _AlumniDashboardScreenState();
}

class _AlumniDashboardScreenState extends State<AlumniDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AlumniController>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alumni = context.watch<AlumniController>();
    final user = context.watch<AuthController>().user;
    final profile = Map<String, dynamic>.from(
      alumni.dashboard?['profile'] as Map? ?? {},
    );
    final preview = (alumni.dashboard?['announcements_preview'] as List?) ?? [];
    final course = profile['course']?.toString().trim();
    final displayCourse = course == null || course.isEmpty
        ? 'Alumni'
        : '$course Alumni';

    return AlumniModuleChrome(
      title: 'Home',
      selectedRoute: AppRoutes.alumniDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(32, 92, 32, 34),
        children: [
          const Text(
            'Events',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 34),
          _LargeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, there! $displayCourse',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Share your memorable experiences with us ${user?.fullName == null ? '' : user!.fullName.split(' ').first}.',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 27,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          if (alumni.loading && alumni.dashboard == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (alumni.error != null && alumni.dashboard == null)
            _LargeCard(
              child: Column(
                children: [
                  Text(alumni.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: alumni.loadDashboard,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (preview.isEmpty)
            const _LargeCard(
              child: Text(
                'No announcements yet.',
                style: TextStyle(fontSize: 28, color: AppColors.muted),
              ),
            )
          else
            ...preview.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 26),
                child: _LargeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']?.toString() ?? 'Announcement',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        item['content']?.toString() ?? '',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 27,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _LargeCard extends StatelessWidget {
  const _LargeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5F0)),
      ),
      child: child,
    );
  }
}
