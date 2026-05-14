import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/service_locator.dart';
import 'core/utils/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  setupServiceLocator();
  runApp(const FleetaraApp());
}

class FleetaraApp extends StatefulWidget {
  const FleetaraApp({super.key});
  @override
  State<FleetaraApp> createState() => _FleetaraAppState();
}

class _FleetaraAppState extends State<FleetaraApp> {
  late final AuthBloc        _authBloc;
  late final GoRouter        _router;
  late final _RouterRefresh  _refresh;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(AuthCheckRequested());
    _refresh  = _RouterRefresh(_authBloc.stream);
    _router   = buildRouter(_authBloc, _refresh);
  }

  @override
  void dispose() {
    _refresh.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title:                      'Fleetara',
        debugShowCheckedModeBanner: false,
        theme:                      AppTheme.lightTheme,
        routerConfig:               _router,
      ),
    );
  }
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
