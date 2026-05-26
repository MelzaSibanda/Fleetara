import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../data/vehicle_model.dart';

// Events
abstract class VehicleEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadVehicles  extends VehicleEvent {}
class DeleteVehicle extends VehicleEvent {
  final String id;
  DeleteVehicle(this.id);
  @override List<Object?> get props => [id];
}

// States
abstract class VehicleState extends Equatable {
  @override List<Object?> get props => [];
}
class VehicleInitial  extends VehicleState {}
class VehicleLoading  extends VehicleState {}
class VehicleDeleting extends VehicleState {}
class VehicleDeleted  extends VehicleState {}
class VehicleError    extends VehicleState {
  final String message;
  VehicleError(this.message);
  @override List<Object?> get props => [message];
}
class VehiclesLoaded extends VehicleState {
  final List<VehicleModel> horses;
  final List<VehicleModel> trailers;
  VehiclesLoaded({required this.horses, required this.trailers});
  @override List<Object?> get props => [horses, trailers];
}

// Bloc
class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final FirestoreService _fs;

  VehicleBloc() : _fs = sl<FirestoreService>(), super(VehicleInitial()) {

    on<LoadVehicles>((event, emit) async {
      emit(VehicleLoading());
      try {
        final snap = await _fs.db.collection('vehicles').get();
        final all = _fs.docsToList(snap);
        final horses   = all.where((v) => v['type'] == 'horse')
            .map((j) => VehicleModel.fromJson(j, type: 'horse')).toList();
        final trailers = all.where((v) => v['type'] == 'trailer')
            .map((j) => VehicleModel.fromJson(j, type: 'trailer')).toList();
        emit(VehiclesLoaded(horses: horses, trailers: trailers));
      } catch (_) {
        emit(VehicleError('Failed to load vehicles.'));
      }
    });

    on<DeleteVehicle>((event, emit) async {
      emit(VehicleDeleting());
      try {
        await _fs.db.collection('vehicles').doc(event.id).delete();
        emit(VehicleDeleted());
      } catch (_) {
        emit(VehicleError('Failed to delete vehicle.'));
      }
    });
  }
}
