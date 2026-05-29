import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/trips/presentation/pages/edit_trip_page.dart';
import '../../features/trips/data/trip_model.dart';
import '../../features/fuel/presentation/pages/fuel_page.dart';
import '../../features/fuel/presentation/pages/add_fuel_page.dart';
import '../../features/invoices/presentation/pages/invoices_page.dart';
import '../../features/invoices/presentation/pages/add_invoice_page.dart';
import '../../features/invoices/presentation/pages/financial_summary_page.dart';
import '../../features/invoices/presentation/pages/invoice_preview_page.dart';
import '../../features/invoices/presentation/pages/statement_generator_page.dart';
import '../../features/invoices/presentation/pages/statement_preview_page.dart';
import '../../features/tyres/presentation/pages/tyres_page.dart';
import '../../features/services/presentation/pages/services_page.dart';
import '../../features/services/presentation/pages/add_service_page.dart';
import '../../features/daily_checks/presentation/pages/daily_checks_page.dart';
import '../../features/driver/presentation/pages/daily_check_form_page.dart';
import '../../features/driver/presentation/pages/daily_check_history_page.dart';
import '../../features/driver/presentation/pages/driver_trips_page.dart';
import '../../features/repairs/presentation/pages/repairs_page.dart';
import '../../features/repairs/presentation/pages/add_repair_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/gps/presentation/pages/live_map_page.dart';

GoRouter buildRouter(AuthBloc authBloc, ChangeNotifier refreshListenable) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState  = authBloc.state;
      final loc        = state.matchedLocation;
      final isAuthPage = loc == '/login' || loc == '/register';

      if (authState is AuthInitial || authState is AuthLoading) {
        return isAuthPage ? null : '/loading';
      }
      if (authState is AuthUnauthenticated && !isAuthPage) return '/login';
      if (authState is AuthAuthenticated   &&  isAuthPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF1DB8A0), strokeWidth: 2),
          ),
        ),
      ),
      GoRoute(path: '/login',    builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/dashboard',
        builder: (context, _) {
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
        builder: (_, state) => TripDetailPage(
          tripId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/trips/:id/edit',
        builder: (_, state) => EditTripPage(
          trip: state.extra as TripModel),
      ),
      GoRoute(path: '/fuel',             builder: (_, __) => const FuelPage()),
      GoRoute(path: '/fuel/add',         builder: (_, __) => const AddFuelPage()),
      GoRoute(path: '/invoices',              builder: (_, __) => const InvoicesPage()),
      GoRoute(path: '/invoices/add',          builder: (_, __) => const AddInvoicePage()),
      GoRoute(path: '/invoices/summary',      builder: (_, __) => const FinancialSummaryPage()),
      GoRoute(path: '/invoices/statement',    builder: (_, __) => const StatementGeneratorPage()),
      GoRoute(
        path: '/invoices/statement/preview',
        builder: (_, state) {
          final p = (state.extra as Map<String, String>?) ?? {};
          return StatementPreviewPage(
            client:      p['client']       ?? '',
            statementNo: p['statement_no'] ?? '',
            fromDate:    p['from_date']    ?? '',
            toDate:      p['to_date']      ?? '',
          );
        },
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (_, state) => InvoicePreviewPage(
          invoiceId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/tyres',            builder: (_, __) => const TyresPage()),
      GoRoute(path: '/services',         builder: (_, __) => const ServicesPage()),
      GoRoute(path: '/services/add',     builder: (_, __) => const AddServicePage()),
      GoRoute(path: '/daily-checks',     builder: (_, __) => const DailyChecksPage()),
      GoRoute(path: '/daily-checks/add', builder: (_, __) => const DailyCheckFormPage()),
      GoRoute(path: '/driver/trips',      builder: (_, __) => const DriverTripsPage()),
      GoRoute(path: '/driver/checks',    builder: (_, __) => const DailyCheckHistoryPage()),
      GoRoute(path: '/driver/checks/add', builder: (_, __) => const DailyCheckFormPage()),
      GoRoute(path: '/repairs',          builder: (_, __) => const RepairsPage()),
      GoRoute(path: '/repairs/add',      builder: (_, __) => const AddRepairPage()),
      GoRoute(path: '/notifications',    builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/gps/live',         builder: (_, __) => const LiveMapPage()),
    ],
  );
}
