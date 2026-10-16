import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/controllers/alumni_controller.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/controllers/theme_controller.dart';
import 'package:bits_mobile_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlumniModuleChrome extends StatelessWidget {
  const AlumniModuleChrome({
    super.key,
    required this.title,
    required this.selectedRoute,
    required this.child,
  });

  final String title;
  final String selectedRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AlumniDrawer(),
      appBar: _AlumniTopBar(title: title),
      bottomNavigationBar: _AlumniBottomNav(selectedRoute: selectedRoute),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            final alumni = context.read<AlumniController>();
            await Future.wait([
              alumni.loadDashboard(),
              alumni.loadProfile(),
              alumni.loadRecords(),
            ]);
          },
          child: child,
        ),
      ),
    );
  }
}

class _AlumniTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _AlumniTopBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          _SquareIconButton(
            tooltip: 'Menu',
            icon: Icons.menu,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _SquareIconButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_none,
          showDot: true,
          onPressed: () => _showAnnouncements(context),
        ),
        const SizedBox(width: 14),
        _SquareIconButton(
          tooltip: 'Dark mode',
          icon: context.watch<ThemeController>().darkMode
              ? Icons.light_mode_outlined
              : Icons.nightlight_round,
          onPressed: () => context.read<ThemeController>().toggle(),
        ),
        const SizedBox(width: 14),
        _ProfileButton(
          onTap: () => Navigator.pushNamed(context, AppRoutes.alumniProfile),
        ),
        const SizedBox(width: 16),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFDDE6F2)),
      ),
    );
  }

  Future<void> _showAnnouncements(BuildContext context) async {
    final alumni = context.read<AlumniController>();
    await alumni.loadAnnouncements();
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final items = context.watch<AlumniController>().announcements;
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
            itemCount: items.isEmpty ? 1 : items.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              if (items.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.notifications_none),
                  title: Text('No announcements yet.'),
                );
              }
              final item = items[index];
              return ListTile(
                leading: const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.primary,
                ),
                title: Text(item['title']?.toString() ?? 'Announcement'),
                subtitle: Text(item['content']?.toString() ?? ''),
              );
            },
          ),
        );
      },
    );
  }
}

class AlumniDrawer extends StatelessWidget {
  const AlumniDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = ModalRoute.of(context)?.settings.name;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              accountName: Text('Alumni Portal'),
              accountEmail: Text('BITS alumni account'),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.school_outlined),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in _alumniNavItems)
                    ListTile(
                      selected: item.route == selected,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: .1,
                      ),
                      leading: Icon(
                        item.icon,
                        color: item.route == selected
                            ? AppColors.primary
                            : null,
                      ),
                      title: Text(item.label),
                      onTap: item.route == selected
                          ? null
                          : () {
                              Navigator.pop(context);
                              Navigator.pushReplacementNamed(
                                context,
                                item.route,
                              );
                            },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
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
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.showDot = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: const Color(0xFFF2F6FD),
          borderRadius: BorderRadius.circular(8),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, size: 24),
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
        ),
        if (showDot)
          const Positioned(
            right: 14,
            top: 14,
            child: CircleAvatar(radius: 5, backgroundColor: AppColors.danger),
          ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFEAF2FF),
          border: Border.all(color: const Color(0xFFB8D6FF), width: 3),
        ),
        child: const Icon(Icons.account_circle_outlined, size: 30),
      ),
    );
  }
}

class _AlumniBottomNav extends StatelessWidget {
  const _AlumniBottomNav({required this.selectedRoute});

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFD9E3F1))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final item in _alumniNavItems.take(4))
              _BottomItem(item: item, selected: item.route == selectedRoute),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.item, required this.selected});

  final _AlumniNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: selected ? null : () => Navigator.pushNamed(context, item.route),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: selected ? Colors.white : AppColors.text,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlumniNavItem {
  const _AlumniNavItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

const _alumniNavItems = [
  _AlumniNavItem('Home', Icons.home_outlined, AppRoutes.alumniDashboard),
  _AlumniNavItem('Profile', Icons.person_outline, AppRoutes.alumniProfile),
  _AlumniNavItem(
    'Yearbook',
    Icons.auto_stories_outlined,
    AppRoutes.alumniYearbook,
  ),
  _AlumniNavItem('Work', Icons.work_outline, AppRoutes.alumniRecords),
  _AlumniNavItem('Events', Icons.event_outlined, AppRoutes.alumniEvents),
  _AlumniNavItem(
    'Change Password',
    Icons.lock_outline,
    AppRoutes.alumniChangePassword,
  ),
];
