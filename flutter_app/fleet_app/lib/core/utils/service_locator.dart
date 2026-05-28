import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/driver/data/datasources/driver_datasource.dart';
import '../../features/driver/presentation/bloc/driver_home_bloc.dart';
import '../../features/driver/presentation/bloc/inspection_bloc.dart';
import '../../features/vehicles/presentation/bloc/vehicle_bloc.dart';
import '../services/firestore_service.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  // Core
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());
  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<FirestoreService>()),
  );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(sl<AuthRemoteDataSource>()),
  );

  // Driver
  sl.registerLazySingleton<DriverDataSource>(
    () => DriverDataSource(sl<FirestoreService>()),
  );
  sl.registerFactory<DriverHomeBloc>(
    () => DriverHomeBloc(sl<DriverDataSource>()),
  );
  sl.registerFactory<InspectionBloc>(
    () => InspectionBloc(sl<DriverDataSource>()),
  );

  // Vehicles
  sl.registerFactory<VehicleBloc>(() => VehicleBloc());
}
