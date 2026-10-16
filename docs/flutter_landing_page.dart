import 'package:flutter/material.dart';

void main() {
  runApp(const CampusHubLandingApp());
}

class CampusHubLandingApp extends StatelessWidget {
  const CampusHubLandingApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF062B4F);
    const royalBlue = Color(0xFF0D6EFD);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusHub BITS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: royalBlue,
          primary: navy,
          secondary: royalBlue,
          tertiary: const Color(0xFF22B8F0),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
      ),
      home: const CampusHubLandingPage(),
    );
  }
}

class CampusHubLandingPage extends StatelessWidget {
  const CampusHubLandingPage({super.key});

  static const _navy = Color(0xFF062B4F);
  static const _royalBlue = Color(0xFF0D6EFD);
  static const _cyan = Color(0xFF22B8F0);
  static const _bg = Color(0xFFF5F7FA);
  static const _ink = Color(0xFF061A2E);
  static const _muted = Color(0xFF637084);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 8,
            shadowColor: _navy.withValues(alpha: .10),
            backgroundColor: Colors.white.withValues(alpha: .96),
            surfaceTintColor: Colors.white,
            toolbarHeight: 74,
            titleSpacing: 0,
            title: const _TopNav(),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: const [
                _HeroSection(),
                _StatsSection(),
                _FeaturesSection(),
                _RolesSection(),
                _OperationsSection(),
                _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 820;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const _LogoMark(size: 42),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "CampusHub BITS",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CampusHubLandingPage._navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              if (isDesktop) ...[
                const _NavLink(label: 'Features'),
                const _NavLink(label: 'Events'),
                const _NavLink(label: 'Roles'),
                const _NavLink(label: 'Contact'),
                const SizedBox(width: 14),
                _ActionButton(
                  label: 'Login',
                  icon: Icons.login_rounded,
                  compact: true,
                  onPressed: () {},
                ),
              ] else
                IconButton.filledTonal(
                  tooltip: 'Open menu',
                  onPressed: () {},
                  icon: const Icon(Icons.menu_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return _SectionShell(
      top: 34,
      bottom: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFEAF7FF), Color(0xFFF5F7FA)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: _softShadow,
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 34 : 18),
          child: isDesktop
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 10, child: _HeroCopy()),
                    SizedBox(width: 34),
                    Expanded(flex: 9, child: _DashboardPreview()),
                  ],
                )
              : const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCopy(),
                    SizedBox(height: 26),
                    _DashboardPreview(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headlineSize = width < 430
        ? 34.0
        : width < 900
        ? 42.0
        : 64.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Pill(
          icon: Icons.verified_user_outlined,
          label: 'Unified student, alumni, and event access',
        ),
        const SizedBox(height: 20),
        Text(
          'CampusHub BITS',
          style: TextStyle(
            color: CampusHubLandingPage._ink,
            fontSize: headlineSize,
            height: .98,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A cleaner campus portal for events, attendance, profiles, alumni records, and scanner workflows.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: CampusHubLandingPage._navy,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Students can discover activities, organizers can manage attendance, alumni can keep records current, and scanners can validate QR codes in a fast Flutter experience built for campus operations.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: CampusHubLandingPage._muted,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionButton(
              label: 'Get Started',
              icon: Icons.rocket_launch_rounded,
              onPressed: () {},
            ),
            _ActionButton(
              label: 'View Events',
              icon: Icons.event_available_rounded,
              secondary: true,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Today in CampusHub',
                  style: TextStyle(
                    color: CampusHubLandingPage._navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: CampusHubLandingPage._navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: _MetricTile(
                  value: '12',
                  label: 'Events',
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  value: '94%',
                  label: 'Attendance',
                  icon: Icons.fact_check_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              final panels = const [
                _MiniPanel(
                  title: 'Scanner',
                  text: 'QR validation ready',
                  icon: Icons.qr_code_scanner_rounded,
                ),
                _MiniPanel(
                  title: 'Alumni',
                  text: 'Records synced',
                  icon: Icons.groups_2_rounded,
                ),
              ];

              if (compact) {
                return const Column(
                  children: [
                    _MiniPanel(
                      title: 'Scanner',
                      text: 'QR validation ready',
                      icon: Icons.qr_code_scanner_rounded,
                    ),
                    SizedBox(height: 12),
                    _MiniPanel(
                      title: 'Alumni',
                      text: 'Records synced',
                      icon: Icons.groups_2_rounded,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: panels[0]),
                  const SizedBox(width: 12),
                  Expanded(child: panels[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const _TimelineRow(
            title: 'Student assembly',
            time: '8:00 AM',
            color: CampusHubLandingPage._royalBlue,
          ),
          const _TimelineRow(
            title: 'Tech showcase',
            time: '1:30 PM',
            color: CampusHubLandingPage._cyan,
          ),
          const _TimelineRow(
            title: 'Alumni meetup',
            time: '5:00 PM',
            color: CampusHubLandingPage._navy,
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    const stats = [
      _InfoSpec(Icons.supervised_user_circle_rounded, '4', 'connected roles'),
      _InfoSpec(Icons.public_rounded, '24/7', 'portal access'),
      _InfoSpec(Icons.qr_code_2_rounded, 'QR', 'attendance scan'),
      _InfoSpec(Icons.hub_rounded, '1', 'campus hub'),
    ];

    return _SectionShell(
      top: 4,
      bottom: 46,
      child: _ResponsiveGrid(
        minTileWidth: 210,
        spacing: 16,
        children: [
          for (final stat in stats)
            _InfoCard(
              icon: stat.icon,
              title: stat.title,
              subtitle: stat.subtitle,
              prominent: true,
            ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    const features = [
      _InfoSpec(
        Icons.event_note_rounded,
        'Event Discovery',
        'Browse campus activities, announcements, and upcoming programs in one place.',
      ),
      _InfoSpec(
        Icons.how_to_reg_rounded,
        'Attendance Tracking',
        'Capture attendance through QR workflows and keep organizer records clear.',
      ),
      _InfoSpec(
        Icons.badge_rounded,
        'Profile Records',
        'Maintain student and alumni details for smoother campus coordination.',
      ),
    ];

    return _SectionShell(
      bottom: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'Main Features',
            title: 'Campus operations in one organized system',
            body:
                "CampusHub BITS gives campus teams the tools to manage users, events, attendance, alumni information, announcements, and reports without jumping between separate systems.",
          ),
          const SizedBox(height: 22),
          _ResponsiveGrid(
            minTileWidth: 260,
            spacing: 18,
            children: [
              for (final feature in features)
                _InfoCard(
                  icon: feature.icon,
                  title: feature.title,
                  subtitle: feature.subtitle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RolesSection extends StatelessWidget {
  const _RolesSection();

  @override
  Widget build(BuildContext context) {
    const roles = [
      _InfoSpec(
        Icons.school_rounded,
        'Students',
        'Find events, view profiles, and keep campus activity close.',
      ),
      _InfoSpec(
        Icons.diversity_3_rounded,
        'Alumni',
        'Maintain alumni records, career details, and campus connection points.',
      ),
      _InfoSpec(
        Icons.admin_panel_settings_rounded,
        'Managers',
        'Create events, monitor attendance, and publish announcements.',
      ),
      _InfoSpec(
        Icons.qr_code_scanner_rounded,
        'Scanners',
        'Validate student QR codes quickly at assigned attendance windows.',
      ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: _SectionShell(
        bottom: 58,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(
              eyebrow: 'Connected Roles',
              title: 'Built for every campus workflow',
              body:
                  'Each role gets a focused experience, from student discovery to manager reporting and scanner validation.',
            ),
            const SizedBox(height: 22),
            _ResponsiveGrid(
              minTileWidth: 230,
              spacing: 18,
              children: [
                for (final role in roles)
                  _RoleCard(
                    icon: role.icon,
                    title: role.title,
                    subtitle: role.subtitle,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationsSection extends StatelessWidget {
  const _OperationsSection();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;

    return _SectionShell(
      top: 58,
      bottom: 58,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CampusHubLandingPage._navy,
              CampusHubLandingPage._royalBlue,
              CampusHubLandingPage._cyan,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: _blueShadow,
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 34 : 22),
          child: isDesktop
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: _OperationsCopy()),
                    SizedBox(width: 28),
                    Expanded(flex: 7, child: _OpsChecklist()),
                  ],
                )
              : const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OperationsCopy(),
                    SizedBox(height: 24),
                    _OpsChecklist(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OperationsCopy extends StatelessWidget {
  const _OperationsCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Pill(
          icon: Icons.lock_outline_rounded,
          label: 'Secure campus operations',
          dark: true,
        ),
        const SizedBox(height: 18),
        Text(
          'Manage your campus smarter with CampusHub BITS',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Access role-based dashboards, event controls, alumni records, scanner tools, and reports through one polished Flutter portal.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: .86),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 22),
        _ActionButton(
          label: 'Login to Portal',
          icon: Icons.login_rounded,
          secondary: true,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF021D35)),
      child: _SectionShell(
        top: 34,
        bottom: 32,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 620;
            final content = [
              const _FooterBrand(),
              const _FooterLinks(
                title: 'Quick Links',
                links: ['Home', 'Features', 'Roles'],
              ),
              const _FooterLinks(
                title: 'Features',
                links: ['Attendance Flow', 'About', 'Contact'],
              ),
              const _FooterPortal(),
            ];

            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in content) ...[
                    item,
                    const SizedBox(height: 22),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 3, child: _FooterBrand()),
                for (final item in content.skip(1))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: item,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.secondary = false,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool secondary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = secondary ? CampusHubLandingPage._navy : Colors.white;
    final background = secondary
        ? Colors.white
        : CampusHubLandingPage._royalBlue;

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 17 : 19),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: secondary ? 0 : 6,
        shadowColor: CampusHubLandingPage._royalBlue.withValues(alpha: .30),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 24,
          vertical: compact ? 12 : 16,
        ),
        textStyle: TextStyle(
          fontSize: compact ? 13 : 15,
          fontWeight: FontWeight.w900,
        ),
        side: secondary
            ? BorderSide(
                color: CampusHubLandingPage._royalBlue.withValues(alpha: .18),
              )
            : BorderSide.none,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(icon: Icons.auto_awesome_rounded, label: eyebrow),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: CampusHubLandingPage._ink,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CampusHubLandingPage._muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.prominent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: icon),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: CampusHubLandingPage._ink,
              fontSize: prominent ? 30 : 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: prominent
                  ? CampusHubLandingPage._navy
                  : CampusHubLandingPage._muted,
              height: 1.45,
              fontWeight: prominent ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: CampusHubLandingPage._ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CampusHubLandingPage._muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EDF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CampusHubLandingPage._royalBlue, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: CampusHubLandingPage._ink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CampusHubLandingPage._muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPanel extends StatelessWidget {
  const _MiniPanel({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CampusHubLandingPage._navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: CampusHubLandingPage._cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.time,
    required this.color,
  });

  final String title;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CampusHubLandingPage._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: CampusHubLandingPage._muted),
          ),
        ],
      ),
    );
  }
}

class _OpsChecklist extends StatelessWidget {
  const _OpsChecklist();

  @override
  Widget build(BuildContext context) {
    const items = [
      _InfoSpec(
        Icons.dashboard_customize_rounded,
        'Role-Based Access Control',
        'Protect dashboards and workflows with role-specific access.',
      ),
      _InfoSpec(
        Icons.badge_rounded,
        'Student Profile Management',
        'Maintain student details, photos, course, year, section, and academic data.',
      ),
      _InfoSpec(
        Icons.qr_code_scanner_rounded,
        'QR Code Attendance Scanning',
        'Record event attendance by scanning assigned student QR codes.',
      ),
    ];

    return Column(
      children: [
        for (final item in items) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBubble(icon: item.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: CampusHubLandingPage._ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CampusHubLandingPage._muted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (item != items.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    this.minTileWidth = 240,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        final width = (constraints.maxWidth - (spacing * (count - 1))) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child, this.top = 0, this.bottom = 0});

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top, 16, bottom),
          child: child,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECF4)),
        boxShadow: _softShadow,
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.dark = false});

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: .16)
            : CampusHubLandingPage._royalBlue.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: .20)
              : CampusHubLandingPage._royalBlue.withValues(alpha: .14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: dark ? Colors.white : CampusHubLandingPage._royalBlue,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: dark ? Colors.white : CampusHubLandingPage._royalBlue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: CampusHubLandingPage._royalBlue.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: CampusHubLandingPage._royalBlue, size: 21),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            CampusHubLandingPage._navy,
            CampusHubLandingPage._royalBlue,
            CampusHubLandingPage._cyan,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: CampusHubLandingPage._royalBlue.withValues(alpha: .25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * .70,
          height: size * .70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .95),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school_rounded,
            size: size * .42,
            color: CampusHubLandingPage._navy,
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        label,
        style: const TextStyle(
          color: CampusHubLandingPage._navy,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CampusHub BITS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A secure campus portal system for users, events, attendance, alumni records, and reports.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({required this.title, required this.links});

  final String title;
  final List<String> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              link,
              style: TextStyle(color: Colors.white.withValues(alpha: .72)),
            ),
          ),
      ],
    );
  }
}

class _FooterPortal extends StatelessWidget {
  const _FooterPortal();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Portal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'Login',
          icon: Icons.person_rounded,
          compact: true,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _InfoSpec {
  const _InfoSpec(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

final _softShadow = [
  BoxShadow(
    color: CampusHubLandingPage._navy.withValues(alpha: .07),
    blurRadius: 24,
    offset: const Offset(0, 12),
  ),
];

final _blueShadow = [
  BoxShadow(
    color: CampusHubLandingPage._royalBlue.withValues(alpha: .28),
    blurRadius: 30,
    offset: const Offset(0, 16),
  ),
];
