import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class AppShell extends StatelessWidget {
  final Widget        child;
  final String        title;
  final List<Widget>? actions;
  final Widget?       floatingActionButton;

  const AppShell({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(
          color: AppTheme.accent, strokeWidth: 2)),
      );
    }
    final user     = authState.user;
    final isWide   = Responsive.isWide(context);
    final items    = _navItemsForRole(user.role);
    final initials = user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 56,
        title: Row(children: [
          Image.asset('assets/logos/fleetara_logo.png', width: 28, height: 28),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ]),
        actions: [
          ...?actions,
          _NotificationBell(),
          const SizedBox(width: 4),
          _UserAvatar(initials: initials, user: user),
          const SizedBox(width: 12),
        ],
      ),
      body: isWide
          ? Row(children: [
              _Sidebar(items: items),
              Expanded(child: child),
            ])
          : child,
      bottomNavigationBar: isWide ? null : _BottomNav(items: items),
      floatingActionButton: floatingActionButton,
    );
  }

  List<_NavItem> _navItemsForRole(String role) {
    if (role == 'driver') {
      return [
        _NavItem('/dashboard',    Icons.home_outlined,                    'Home'),
        _NavItem('/trips',        Icons.route_outlined,                   'Trips'),
        _NavItem('/daily-checks', Icons.assignment_turned_in_outlined,    'Daily Checks'),
        _NavItem('/fuel',         Icons.local_gas_station_outlined,       'Fuel'),
        _NavItem('/repairs',      Icons.handyman_outlined,                'Repairs'),
      ];
    }
    if (role == 'fleet_manager') {
      return [
        _NavItem('/vehicles',     Icons.local_shipping_outlined,          'Vehicles'),
        _NavItem('/trips',        Icons.route_outlined,                   'Trips'),
        _NavItem('/daily-checks', Icons.assignment_turned_in_outlined,    'Daily Checks'),
        _NavItem('/fuel',         Icons.local_gas_station_outlined,       'Fuel'),
        _NavItem('/tyres',        Icons.tire_repair_outlined,             'Tyres'),
        _NavItem('/services',     Icons.build_circle_outlined,            'Services'),
        _NavItem('/repairs',      Icons.handyman_outlined,                'Repairs'),
        _NavItem('/gps/live',     Icons.location_on_outlined,             'GPS'),
      ];
    }
    return [
      _NavItem('/dashboard', Icons.home_outlined,           'Home'),
      _NavItem('/vehicles',  Icons.local_shipping_outlined, 'Fleet'),
      _NavItem('/trips',     Icons.route_outlined,          'Trips'),
      _NavItem('/fuel',      Icons.local_gas_station_outlined, 'Fuel'),
      _NavItem('/invoices',  Icons.receipt_long_outlined,   'Finance'),
      _NavItem('/gps/live',  Icons.location_on_outlined,    'GPS'),
    ];
  }
}

// ── AppBar components ──────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined, size: 21,
          color: AppTheme.textMuted),
        onPressed: () {},
      ),
      Positioned(
        right: 11, top: 11,
        child: Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(
            color: AppTheme.rose, shape: BoxShape.circle),
        ),
      ),
    ],
  );
}

class _UserAvatar extends StatelessWidget {
  final String initials;
  final dynamic user;
  const _UserAvatar({required this.initials, required this.user});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    offset: const Offset(0, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 8,
    shadowColor: const Color(0x1A1E3A72),
    icon: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Text(initials,
        style: const TextStyle(color: Colors.white, fontSize: 13,
          fontWeight: FontWeight.w700))),
    ),
    itemBuilder: (_) => [
      PopupMenuItem(
        enabled: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.fullName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(user.roleLabel,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ]),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        onTap: () => _confirmSignOut(context),
        child: const Row(children: [
          Icon(Icons.logout_outlined, size: 16, color: AppTheme.rose),
          SizedBox(width: 10),
          Text('Sign out', style: TextStyle(fontSize: 13, color: AppTheme.rose)),
        ]),
      ),
    ],
  );

  void _confirmSignOut(BuildContext context) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign out'),
      content: const Text('Are you sure you want to sign out?',
        style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<AuthBloc>().add(AuthLogoutRequested());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.rose, minimumSize: const Size(90, 38)),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
}

// ── Sidebar ────────────────────────────────────────────────────────────────

class _NavItem {
  final String   route, label;
  final IconData icon;
  const _NavItem(this.route, this.icon, this.label);
}

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  const _Sidebar({required this.items});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 210,
      decoration: const BoxDecoration(
        color: AppTheme.darkNavy,
        border: Border(right: BorderSide(
          color: Color(0x18FFFFFF), width: 0.5)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: items.map((item) {
              final active = location.startsWith(item.route) &&
                  (item.route != '/dashboard' || location == '/dashboard');
              return _SidebarItem(item: item, active: active);
            }).toList(),
          ),
        ),
        Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
        Padding(
          padding: const EdgeInsets.all(8),
          child: _SidebarItem(
            item: _NavItem('/settings', Icons.settings_outlined, 'Settings'),
            active: location.startsWith('/settings'),
          ),
        ),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool     active;
  const _SidebarItem({required this.item, required this.active});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go(item.route),
    child: Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: active
          ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5)
          : null,
      ),
      child: Row(children: [
        // Left accent bar
        Container(
          width: 3, height: 20,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Icon(item.icon, size: 17,
          color: active
            ? Colors.white
            : Colors.white.withValues(alpha: 0.45)),
        const SizedBox(width: 9),
        Expanded(child: Text(item.label,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: active
              ? Colors.white
              : Colors.white.withValues(alpha: 0.45),
          ),
        )),
      ]),
    ),
  );
}

// ── Bottom Navigation ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  const _BottomNav({required this.items});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final trimmed  = items.length > 5 ? items.sublist(0, 5) : items;
    int selected = 0;
    for (int i = 0; i < trimmed.length; i++) {
      if (location.startsWith(trimmed[i].route)) { selected = i; break; }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A72).withValues(alpha: 0.06),
            blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selected,
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (i) => context.go(trimmed[i].route),
        destinations: trimmed.map((item) => NavigationDestination(
          icon: Icon(item.icon, color: AppTheme.textMuted, size: 20),
          selectedIcon: Icon(item.icon, color: AppTheme.accent, size: 20),
          label: item.label,
        )).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable design components
// ══════════════════════════════════════════════════════════════════════════════

/// Elevated card with subtle navy shadow.
class FleetCard extends StatelessWidget {
  final Widget  child;
  final EdgeInsetsGeometry padding;
  final VoidCallback?      onTap;
  final Color?             color;
  final double             radius;

  const FleetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1E3A72),
            blurRadius: 20, spreadRadius: 0, offset: Offset(0, 6)),
          BoxShadow(
            color: Color(0x071E3A72),
            blurRadius: 4,  spreadRadius: 0, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

/// Status badge pill.
class StatusPill extends StatelessWidget {
  final String label;
  final Color  color;
  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: color.withValues(alpha: 0.9))),
  );
}

/// Thin progress bar that shifts colour as value increases.
class FleetProgressBar extends StatelessWidget {
  final double value;
  const FleetProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value > 0.95 ? AppTheme.rose
        : value > 0.80 ? AppTheme.amber
        : AppTheme.accent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 5,
        backgroundColor: AppTheme.border,
        color: color,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title,
      style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary, letterSpacing: 0.1)),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String   title, subtitle;
  final Widget?  action;
  const EmptyState({super.key, required this.icon, required this.title,
    required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppTheme.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, size: 34, color: AppTheme.textMuted.withValues(alpha: 0.5)),
      ),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      Text(subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        textAlign: TextAlign.center),
      if (action != null) ...[const SizedBox(height: 20), action!],
    ]),
  );
}
