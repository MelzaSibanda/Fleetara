import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/owner_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/driver_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/manager_dashboard_page.dart';
import '../../features/vehicles/presentation/pages/vehicles_page.dart';
import '../../features/vehicles/presentation/pages/add_vehicle_page.dart';
import '../../features/trips/presentation/pages/trips_page.dart';
import '../../features/trips/presentation/pages/add_trip_page.dart';
import '../../features/trips/presentation/pages/trip_detail_page.dart';
import '../../features/fuel/presentation/pages/fuel_page.dart';
import '../../features/fuel/presentation/pages/add_fuel_page.dart';
import '../../features/invoices/presentation/pages/invoices_page.dart';
import '../../features/invoices/presentation/pages/add_invoice_page.dart';
import '../../features/invoices/presentation/pages/financial_summary_page.dart';
import '../../features/tyres/presentation/pages/tyres_page.dart';
import '../../features/repairs/presentation/pages/repairs_page.dart';
import '../../features/repairs/presentation/pages/add_repair_page.dart';
import '../../features/gps/presentation/pages/live_map_page.dart';
import '../../features/driver/presentation/pages/driver_trips_page.dart';
import '../../features/driver/presentation/pages/daily_check_history_page.dart';
import '../../features/driver/presentation/pages/daily_check_form_page.dart';

GoRouter buildRouter(AuthBloc authBloc, ChangeNotifier refreshListenable) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = authBloc.state;
      final loc  = state.matchedLocation;
      final isAuthPage = loc == '/login' || loc == '/register';
      final isSplash   = loc == '/splash';

      // App just launched — show splash while checking stored session
      if (auth is AuthInitial) return isSplash ? null : '/splash';

      // Authenticated: redirect away from auth/splash pages to dashboard
      if (auth is AuthAuthenticated && (isAuthPage || isSplash)) {
        return '/dashboard';
      }

      // Not authenticated: redirect protected routes to login
      if (auth is AuthUnauthenticated && !isAuthPage) return '/login';

      return null;
    },
    routes: [
      GoRoute(path: '/splash',   builder: (_, __) => const _SplashPage()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final auth = authBloc.state;
          if (auth is AuthAuthenticated) {
            final role = auth.user.role;
            if (role == 'owner' || role == 'admin') return const OwnerDashboardPage();
            if (role == 'fleet_manager')            return const ManagerDashboardPage();
            return const DriverDashboardPage();
          }
          return const LoginPage();
        },
      ),
      GoRoute(path: '/vehicles',         builder: (_, __) => const VehiclesPage()),
      GoRoute(path: '/vehicles/add',     builder: (_, __) => const AddVehiclePage()),
      GoRoute(path: '/trips',            builder: (_, __) => const TripsPage()),
      GoRoute(path: '/trips/add',        builder: (_, __) => const AddTripPage()),
      GoRoute(
        path: '/trips/:id',
        builder: (_, state) => TripDetailPage(tripId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/fuel',             builder: (_, __) => const FuelPage()),
      GoRoute(path: '/fuel/add',         builder: (_, __) => const AddFuelPage()),
      GoRoute(path: '/invoices',         builder: (_, __) => const InvoicesPage()),
      GoRoute(path: '/invoices/add',     builder: (_, __) => const AddInvoicePage()),
      GoRoute(path: '/invoices/summary', builder: (_, __) => const FinancialSummaryPage()),
      GoRoute(path: '/tyres',            builder: (_, __) => const TyresPage()),
      GoRoute(path: '/repairs',          builder: (_, __) => const RepairsPage()),
      GoRoute(path: '/repairs/add',      builder: (_, __) => const AddRepairPage()),
      GoRoute(path: '/driver/trips',      builder: (_, __) => const DriverTripsPage()),
      GoRoute(path: '/driver/checks',     builder: (_, __) => const DailyCheckHistoryPage()),
      GoRoute(path: '/driver/checks/add', builder: (_, __) => const DailyCheckFormPage()),
      GoRoute(path: '/gps/live',         builder: (_, __) => const LiveMapPage()),
    ],
  );
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Fleetara',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
