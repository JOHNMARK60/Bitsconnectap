import 'package:bits_mobile_app/app/routes.dart';
import 'package:bits_mobile_app/core/constants/api_config.dart';
import 'package:bits_mobile_app/controllers/auth_controller.dart';
import 'package:bits_mobile_app/core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

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
            automaticallyImplyLeading: false,
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
              children: [
                _HeroSection(),
                _StatsSection(),
                _FeaturesSection(),
                _RolesSection(),
                _EventsSection(),
                _OperationsSection(),
                _AboutSection(),
                _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openLoginModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _LoginPortalDialog(),
  );
}

Future<void> _openVersionNotes(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("What's new"),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.1+2',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text('Released August 12, 2026'),
            SizedBox(height: 16),
            Text('• Displays the app version in the landing-page footer.'),
            SizedBox(height: 8),
            Text('• Adds Android update checks and update notifications.'),
            SizedBox(height: 8),
            Text('• Uses the supported mobile API endpoints.'),
            SizedBox(height: 8),
            Text('• Prevents overlapping attendance and scanner requests.'),
            SizedBox(height: 8),
            Text('• Improves scanner error messages and reliability.'),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

Future<void> _openLandingMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          const ListTile(
            leading: Icon(Icons.apps_rounded, color: LandingScreen._royalBlue),
            title: Text(
              'BITSConnect',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text('Explore the platform'),
          ),
          const Divider(),
          for (final item in const [
            (Icons.auto_awesome_outlined, 'Features'),
            (Icons.event_outlined, 'Events'),
            (Icons.groups_outlined, 'Roles'),
            (Icons.support_agent_outlined, 'Contact'),
          ])
            ListTile(
              leading: Icon(item.$1),
              title: Text(item.$2),
              onTap: () => Navigator.pop(sheetContext),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.login_rounded,
              color: LandingScreen._royalBlue,
            ),
            title: const Text(
              'Login',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              _openLoginModal(context);
            },
          ),
        ],
      ),
    ),
  );
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BITSConnect",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: LandingScreen._navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      ApiConfig.versionLabel,
                      style: TextStyle(
                        color: LandingScreen._muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                  onPressed: () => _openLoginModal(context),
                ),
              ] else
                IconButton.filledTonal(
                  tooltip: 'Open menu',
                  onPressed: () => _openLandingMenu(context),
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
          icon: Icons.face_retouching_natural,
          label: 'Face attendance for campus events',
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: LandingScreen._ink,
              fontSize: headlineSize,
              height: 1.02,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            children: const [
              TextSpan(text: 'Attendance made '),
              TextSpan(
                text: 'simple.',
                style: TextStyle(color: LandingScreen._royalBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Record event attendance with secure face recognition and a clear campus workflow.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: LandingScreen._navy,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Students can verify attendance quickly, while campus teams manage events, attendance windows, records, and reports in one place.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: LandingScreen._muted,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionButton(
              label: 'Explore Face Attendance',
              icon: Icons.face_retouching_natural,
              onPressed: () => _openLoginModal(context),
            ),
            _ActionButton(
              label: 'View Events',
              icon: Icons.event_available_rounded,
              secondary: true,
              onPressed: () => _openLoginModal(context),
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
                  'Face attendance',
                  style: TextStyle(
                    color: LandingScreen._navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: LandingScreen._navy,
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
                  value: 'Face',
                  label: 'Verification',
                  icon: Icons.face_retouching_natural,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  value: 'Event',
                  label: 'Based records',
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
                  title: 'Attendance windows',
                  text: 'Control when check-in is available',
                  icon: Icons.schedule_rounded,
                ),
                _MiniPanel(
                  title: 'Clear reporting',
                  text: 'Review records when you need them',
                  icon: Icons.assessment_outlined,
                ),
              ];

              if (compact) {
                return const Column(
                  children: [
                    _MiniPanel(
                      title: 'Attendance windows',
                      text: 'Control when check-in is available',
                      icon: Icons.schedule_rounded,
                    ),
                    SizedBox(height: 12),
                    _MiniPanel(
                      title: 'Clear reporting',
                      text: 'Review records when you need them',
                      icon: Icons.assessment_outlined,
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
            title: 'Create an event',
            time: 'Setup',
            color: LandingScreen._royalBlue,
          ),
          const _TimelineRow(
            title: 'Verify attendance',
            time: 'Check-in',
            color: LandingScreen._cyan,
          ),
          const _TimelineRow(
            title: 'Review the records',
            time: 'Reports',
            color: LandingScreen._navy,
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
      _InfoSpec(Icons.face_retouching_natural, 'Face', 'attendance'),
      _InfoSpec(Icons.calendar_month_rounded, 'Event', 'management'),
      _InfoSpec(Icons.fact_check_rounded, 'Attendance', 'records'),
      _InfoSpec(Icons.hub_rounded, 'BITSConnect', 'campus platform'),
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
        Icons.face_retouching_natural,
        'Face Attendance',
        'Verify student identity and record attendance for the selected event.',
      ),
      _InfoSpec(
        Icons.event_note_rounded,
        'Event Management',
        'Create events, set attendance windows, and keep activities organized.',
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
                "BITSConnect gives campus teams the tools to manage users, events, attendance, alumni information, announcements, and reports without jumping between separate systems.",
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
              title: 'A focused experience for every role',
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

class _EventsSection extends StatelessWidget {
  const _EventsSection();

  @override
  Widget build(BuildContext context) {
    const steps = [
      _InfoSpec(
        Icons.add_circle_outline_rounded,
        'Create an event',
        'Set the event details and define when attendance can be recorded.',
      ),
      _InfoSpec(
        Icons.face_retouching_natural,
        'Verify attendance',
        'Students use face attendance to check in during the open window.',
      ),
      _InfoSpec(
        Icons.assessment_outlined,
        'Review the records',
        'Campus teams can review attendance linked to the event.',
      ),
    ];

    return _SectionShell(
      top: 8,
      bottom: 58,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: _SectionHeading(
              eyebrow: 'Events',
              title: 'From event creation to attendance',
              body:
                  'A simple flow for setting up an event, opening attendance, and reviewing the records afterward.',
            ),
          ),
          const SizedBox(height: 22),
          _ResponsiveGrid(
            minTileWidth: 250,
            spacing: 18,
            children: [
              for (var index = 0; index < steps.length; index++)
                _InfoCard(
                  icon: steps[index].icon,
                  title: '${index + 1}. ${steps[index].title}',
                  subtitle: steps[index].subtitle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      top: 0,
      bottom: 58,
      child: _GlassCard(
        padding: const EdgeInsets.all(26),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final copy = const _SectionHeading(
              eyebrow: 'About',
              title: 'Built for campus event monitoring and student records',
              body:
                  'BITSConnect is designed to simplify campus event monitoring, student record management, alumni tracking, and attendance through a secure role-based platform.',
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: 20),
                  const Center(child: _LogoMark(size: 110)),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: copy),
                const SizedBox(width: 28),
                const _LogoMark(size: 120),
              ],
            );
          },
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
              LandingScreen._navy,
              LandingScreen._royalBlue,
              LandingScreen._cyan,
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
          icon: Icons.lan_rounded,
          label: 'Campus Operations',
          dark: true,
        ),
        const SizedBox(height: 18),
        Text(
          'Manage your campus smarter with BITSConnect',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Access role-based dashboards, event controls, alumni records, scanner tools, and reports through one polished campus portal.',
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
          onPressed: () => _openLoginModal(context),
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
    final foreground = secondary ? LandingScreen._navy : Colors.white;
    final background = secondary ? Colors.white : LandingScreen._royalBlue;

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 17 : 19),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: secondary ? 0 : 6,
        shadowColor: LandingScreen._royalBlue.withValues(alpha: .30),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 24,
          vertical: compact ? 12 : 16,
        ),
        textStyle: TextStyle(
          fontSize: compact ? 13 : 15,
          fontWeight: FontWeight.w900,
        ),
        side: secondary
            ? BorderSide(color: LandingScreen._royalBlue.withValues(alpha: .18))
            : BorderSide.none,
      ),
    );
  }
}

class _LoginPortalDialog extends StatefulWidget {
  const _LoginPortalDialog();

  @override
  State<_LoginPortalDialog> createState() => _LoginPortalDialogState();
}

class _LoginPortalDialogState extends State<_LoginPortalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController?>();
    final loading = auth?.loading ?? false;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0E7F0)),
            boxShadow: [
              BoxShadow(
                color: LandingScreen._navy.withValues(alpha: .18),
                blurRadius: 36,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _LogoMark(size: 48),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login Portal',
                              style: TextStyle(
                                color: LandingScreen._ink,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Access your BITSConnect dashboard.',
                              style: TextStyle(
                                color: LandingScreen._muted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ModalTextField(
                    controller: _email,
                    label: 'Email',
                    hintText: 'student@bits-edu.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  _ModalTextField(
                    controller: _password,
                    label: 'Password',
                    hintText: '********',
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: Validators.required,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  if (auth?.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      auth!.error!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: loading ? null : _login,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded),
                    label: const Text('Login'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: LandingScreen._royalBlue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Don't have an account? Contact Administration",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LandingScreen._muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController?>();
    if (auth == null) return;

    final ok = await auth.login(_email.text.trim(), _password.text);
    if (!ok || !mounted) return;

    final user = auth.user!;
    Navigator.pushNamedAndRemoveUntil(
      context,
      user.isStudent
          ? AppRoutes.studentDashboard
          : user.isAlumni
          ? AppRoutes.alumniDashboard
          : AppRoutes.scannerDashboard,
      (_) => false,
    );
  }
}

class _ModalTextField extends StatelessWidget {
  const _ModalTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: LandingScreen._ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon, color: LandingScreen._muted),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: LandingScreen._royalBlue,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFDC2626),
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
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
              color: LandingScreen._ink,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LandingScreen._muted,
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
              color: LandingScreen._ink,
              fontSize: prominent ? 30 : 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: prominent ? LandingScreen._navy : LandingScreen._muted,
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
                    color: LandingScreen._ink,
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
              color: LandingScreen._muted,
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
          Icon(icon, color: LandingScreen._royalBlue, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: LandingScreen._ink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LandingScreen._muted,
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
        color: LandingScreen._navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: LandingScreen._cyan),
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
                color: LandingScreen._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: LandingScreen._muted),
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
        Icons.face_retouching_natural,
        'Face Attendance',
        'Verify student identity and record attendance for the selected event.',
      ),
      _InfoSpec(
        Icons.dashboard_customize_rounded,
        'Role-Based Access Control',
        'Protect dashboards and workflows with role-specific access.',
      ),
      _InfoSpec(
        Icons.file_present_rounded,
        'Export-Ready Reports',
        'Review attendance and campus records when you need them.',
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
                          color: LandingScreen._ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LandingScreen._muted,
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
            : LandingScreen._royalBlue.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: .20)
              : LandingScreen._royalBlue.withValues(alpha: .14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: dark ? Colors.white : LandingScreen._royalBlue,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: dark ? Colors.white : LandingScreen._royalBlue,
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
        color: LandingScreen._royalBlue.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: LandingScreen._royalBlue, size: 21),
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
        boxShadow: [
          BoxShadow(
            color: LandingScreen._royalBlue.withValues(alpha: .25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/images/bits_logo.jpg', fit: BoxFit.cover),
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
          color: LandingScreen._navy,
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
            "BITSConnect",
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
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _openVersionNotes(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'App ${ApiConfig.versionLabel} • View release notes',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: .45),
                ),
              ),
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
          onPressed: () => _openLoginModal(context),
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
    color: LandingScreen._navy.withValues(alpha: .07),
    blurRadius: 24,
    offset: const Offset(0, 12),
  ),
];

final _blueShadow = [
  BoxShadow(
    color: LandingScreen._royalBlue.withValues(alpha: .28),
    blurRadius: 30,
    offset: const Offset(0, 16),
  ),
];
