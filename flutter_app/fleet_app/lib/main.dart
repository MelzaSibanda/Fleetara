import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/service_locator.dart';
import 'core/utils/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

void main() {
  setupServiceLocator();
  runApp(const FleetaraApp());
}

class FleetaraApp extends StatelessWidget {
  const FleetaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp.router(
        title:                      'Fleetara',
        debugShowCheckedModeBanner: false,
        theme:                      AppTheme.lightTheme,
        routerConfig:               appRouter,
      ),
    );
  }
}
