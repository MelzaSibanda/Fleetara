import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isAuth    = state.matchedLocation == '/login' ||
                      state.matchedLocation == '/register';
    if (authState is AuthUnauthenticated && !isAuth) return '/login';
    if (authState is AuthAuthenticated   &&  isAuth)  return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login',    builder: (_, __) => const LoginPage()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) {
        final auth = context.read<AuthBloc>().state;
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
    GoRoute(path: '/gps/live',         builder: (_, __) => const LiveMapPage()),
  ],
);
