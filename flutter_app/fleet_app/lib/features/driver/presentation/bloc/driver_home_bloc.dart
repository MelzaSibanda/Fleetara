import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/driver_datasource.dart';
import 'driver_home_event.dart';
import 'driver_home_state.dart';

class DriverHomeBloc extends Bloc<DriverHomeEvent, DriverHomeState> {
  final DriverDataSource _ds;

  DriverHomeBloc(this._ds) : super(DriverHomeInitial()) {
    on<DriverHomeFetchRequested>((event, emit) async {
      emit(DriverHomeLoading());
      try {
        final data = await _ds.getHomeData();
        emit(DriverHomeLoaded(
          activeTrip: data['active_trip'] as Map<String, dynamic>?,
          vehicle:    data['vehicle']    as Map<String, dynamic>?,
        ));
      } catch (e) {
        emit(DriverHomeError(e.toString()));
      }
    });
  }
}
