import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final user   = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final isWide = MediaQuery.of(context).size.width > 800;
    final navItems = _navItemsForRole(user.role);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text(title),
        ]),
        actions: [
          ...?actions,
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: AppTheme.primary,
              radius: 14,
              child: Text(
                user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            itemBuilder: (_) => <PopupMenuEntry>[
              PopupMenuItem(
                enabled: false,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(user.fullName),
                  subtitle: Text(user.roleLabel),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                child: const ListTile(
                  dense: true,
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Sign out', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
        ? Row(children: [
            NavigationRail(
              backgroundColor: AppTheme.surface,
              selectedIndex: _selectedIndex(context, navItems),
              onDestinationSelected: (i) => context.go(navItems[i]['route'] as String),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppTheme.primary),
              selectedLabelTextStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
              destinations: navItems.map((item) => NavigationRailDestination(
                icon: Icon(item['icon'] as IconData),
                label: Text(item['label'] as String),
              )).toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ])
        : child,
      bottomNavigationBar: isWide ? null : NavigationBar(
        selectedIndex: _selectedIndex(context, navItems),
        onDestinationSelected: (i) => context.go(navItems[i]['route'] as String),
        destinations: navItems.map((item) => NavigationDestination(
          icon: Icon(item['icon'] as IconData),
          label: item['label'] as String,
        )).toList(),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  int _selectedIndex(BuildContext context, List<Map<String, dynamic>> items) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i]['route'] as String)) return i;
    }
    return 0;
  }

  List<Map<String, dynamic>> _navItemsForRole(String role) {
    if (role == 'driver') {
      return [
        {'route': '/dashboard', 'icon': Icons.home_outlined,    'label': 'Home'},
        {'route': '/trips',     'icon': Icons.route,             'label': 'Trips'},
        {'route': '/fuel',      'icon': Icons.local_gas_station, 'label': 'Fuel'},
        {'route': '/repairs',   'icon': Icons.build_outlined,    'label': 'Repairs'},
      ];
    }
    return [
      {'route': '/dashboard', 'icon': Icons.home_outlined,    'label': 'Home'},
      {'route': '/vehicles',  'icon': Icons.local_shipping,   'label': 'Vehicles'},
      {'route': '/trips',     'icon': Icons.route,             'label': 'Trips'},
      {'route': '/fuel',      'icon': Icons.local_gas_station, 'label': 'Fuel'},
      {'route': '/invoices',  'icon': Icons.receipt_long,      'label': 'Invoices'},
      {'route': '/gps/live',  'icon': Icons.map_outlined,      'label': 'Live Map'},
    ];
  }
}
