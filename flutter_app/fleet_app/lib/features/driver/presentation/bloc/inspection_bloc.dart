import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/driver_datasource.dart';
import 'inspection_event.dart';
import 'inspection_state.dart';

class InspectionBloc extends Bloc<InspectionEvent, InspectionState> {
  final DriverDataSource _ds;

  InspectionBloc(this._ds) : super(InspectionInitial()) {
    on<InspectionHistoryRequested>((event, emit) async {
      emit(InspectionLoading());
      try {
        final checks = await _ds.getDailyChecks();
        emit(InspectionHistoryLoaded(checks));
      } catch (e) {
        emit(InspectionError(e.toString()));
      }
    });

    on<InspectionSubmitRequested>((event, emit) async {
      emit(InspectionLoading());
      try {
        await _ds.submitDailyCheck(event.data);
        emit(InspectionSubmitSuccess());
      } catch (e) {
        emit(InspectionError(e.toString()));
      }
    });
  }
}
