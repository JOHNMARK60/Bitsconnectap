import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:bits_mobile_app/core/widgets/brand_logo.dart';
import 'package:bits_mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PortalScaffold extends StatelessWidget {
  const PortalScaffold({
    required this.title,
    required this.children,
    required this.items,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final List<PortalNavItem> items;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: .1),
              child: Text(user?.fullName.substring(0, 1).toUpperCase() ?? 'B'),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'BITSConnect',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(user?.role ?? 'Mobile'),
                leading: const BrandLogo(size: 42),
              ),
              const Divider(),
              ...items.map(
                (item) => ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, item.route);
                  },
                ),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () async {
                  final shouldLogout = await showConfirmationDialog(
                    context,
                    'Logout',
                    'Do you want to sign out?',
                  );
                  if (!shouldLogout || !context.mounted) return;
                  await context.read<AuthController>().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(padding: const EdgeInsets.all(18), children: children),
      ),
    );
  }
}

class PortalNavItem {
  const PortalNavItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
