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
    final user     = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final isDesktop = Responsive.isDesktop(context);
    final isMobile  = Responsive.isMobile(context);
    final items     = _navItemsForRole(user.role);
    final initials  = user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 56,
        title: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ]),
        actions: [
          ...?actions,
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22, color: AppTheme.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                right: 10, top: 10,
                child: Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: AppTheme.rose, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppTheme.primary,
              radius: 16,
              child: Text(initials,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(AuthLogoutRequested());
                context.go('/login');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  Text(user.roleLabel, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 16, color: AppTheme.rose),
                  SizedBox(width: 8),
                  Text('Sign out', style: TextStyle(fontSize: 13, color: AppTheme.rose)),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop
          ? Row(children: [
              _Sidebar(items: items),
              const VerticalDivider(width: 0.5, thickness: 0.5, color: AppTheme.border),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: child,
                  ),
                ),
              ),
            ])
          : child,
      bottomNavigationBar: isDesktop ? null : _BottomNav(items: items, compact: isMobile),
      floatingActionButton: floatingActionButton,
    );
  }

  List<_NavItem> _navItemsForRole(String role) {
    if (role == 'driver') {
      return [
        _NavItem('/dashboard',     Icons.home_outlined,         'Home'),
        _NavItem('/driver/trips',  Icons.route_outlined,         'Trips'),
        _NavItem('/driver/checks', Icons.checklist_outlined,     'Checks'),
        _NavItem('/fuel',          Icons.local_gas_station,      'Fuel'),
        _NavItem('/repairs',       Icons.build_outlined,         'Issues'),
      ];
    }
    return [
      _NavItem('/dashboard', Icons.home_outlined,        'Home'),
      _NavItem('/vehicles',  Icons.local_shipping_outlined,'Fleet'),
      _NavItem('/trips',     Icons.route_outlined,         'Trips'),
      _NavItem('/fuel',      Icons.local_gas_station,      'Fuel'),
      _NavItem('/invoices',  Icons.receipt_long_outlined,  'Finance'),
      _NavItem('/gps/live',  Icons.map_outlined,           'GPS'),
    ];
  }
}

class _NavItem {
  final String   route;
  final IconData icon;
  final String   label;
  const _NavItem(this.route, this.icon, this.label);
}

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  const _Sidebar({required this.items});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 200,
      color: AppTheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: items.map((item) {
                final active = location.startsWith(item.route);
                return _SidebarItem(item: item, active: active);
              }).toList(),
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _SidebarItem(
              item: _NavItem('/settings', Icons.settings_outlined, 'Settings'),
              active: location.startsWith('/settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool     active;
  const _SidebarItem({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.route),
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(item.icon, size: 18,
            color: active ? AppTheme.primary : AppTheme.textMuted),
          const SizedBox(width: 10),
          Text(item.label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: active ? AppTheme.primary : AppTheme.textMuted,
            )),
        ]),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final bool compact;
  const _BottomNav({required this.items, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int selected = 0;
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) { selected = i; break; }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: NavigationBar(
        selectedIndex: selected,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.18),
        onDestinationSelected: (i) => context.go(items[i].route),
        destinations: items.map((item) => NavigationDestination(
          icon: Icon(item.icon, color: AppTheme.textMuted, size: compact ? 22 : 20),
          selectedIcon: Icon(item.icon, color: AppTheme.primary, size: compact ? 22 : 20),
          label: compact ? '' : item.label,
        )).toList(),
      ),
    );
  }
}

// Reusable components used across screens

class StatusPill extends StatelessWidget {
  final String label;
  final Color  color;

  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
          color: color.withValues(alpha: 0.9))),
    );
  }
}

class FleetProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  const FleetProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value > 0.95 ? AppTheme.rose
        : value > 0.80 ? AppTheme.amber
        : AppTheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
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
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Widget?  action;
  const EmptyState({super.key, required this.icon, required this.title,
    required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: AppTheme.border),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ]),
    );
  }
}
