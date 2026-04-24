import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/vehicles/presentation/bloc/vehicle_bloc.dart';
import '../network/api_client.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(sl<AuthRemoteDataSource>()),
  );

  // Vehicles
  sl.registerFactory<VehicleBloc>(() => VehicleBloc());
}
