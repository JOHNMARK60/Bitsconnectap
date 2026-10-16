import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/alumni_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/widgets/empty_view.dart';
import 'package:bits_mobile_app/core/widgets/error_view.dart';
import 'package:bits_mobile_app/core/widgets/event_card.dart';
import 'package:bits_mobile_app/core/widgets/loading_view.dart';
import 'package:bits_mobile_app/screens/alumni/alumni_module_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlumniEventsScreen extends StatefulWidget {
  const AlumniEventsScreen({super.key});

  @override
  State<AlumniEventsScreen> createState() => _AlumniEventsScreenState();
}

class _AlumniEventsScreenState extends State<AlumniEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AlumniController>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AlumniController>();
    return AlumniModuleChrome(
      title: 'Events',
      selectedRoute: AppRoutes.alumniEvents,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(32, 54, 32, 32),
        children: [
          const Text(
            'Events',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'View available alumni and campus activities.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 20,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          if (controller.loading)
            const SizedBox(height: 320, child: LoadingView())
          else if (controller.error != null)
            ErrorView(
              message: controller.error!,
              onRetry: controller.loadEvents,
            )
          else if (controller.events.isEmpty)
            const SizedBox(
              height: 320,
              child: EmptyView(message: 'No events found.'),
            )
          else
            ...controller.events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EventCard(event: event),
              ),
            ),
        ],
      ),
    );
  }
}
