import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../data/vehicle_model.dart';

// Events
abstract class VehicleEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadVehicles  extends VehicleEvent {}
class DeleteVehicle extends VehicleEvent {
  final int id; final String type;
  DeleteVehicle(this.id, this.type);
  @override List<Object?> get props => [id, type];
}

// States
abstract class VehicleState extends Equatable {
  @override List<Object?> get props => [];
}
class VehicleInitial extends VehicleState {}
class VehicleLoading extends VehicleState {}
class VehicleError   extends VehicleState {
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
  final ApiClient _client;

  VehicleBloc() : _client = sl<ApiClient>(), super(VehicleInitial()) {
    on<LoadVehicles>((event, emit) async {
      emit(VehicleLoading());
      try {
        final hRes = await _client.dio.get('/vehicles/horses/');
        final tRes = await _client.dio.get('/vehicles/trailers/');
        final horses = ((hRes.data['results'] ?? hRes.data) as List)
            .map<VehicleModel>((j) => VehicleModel.fromJson(j)).toList();
        final trailers = ((tRes.data['results'] ?? tRes.data) as List)
            .map<VehicleModel>((j) => VehicleModel.fromJson(j)).toList();
        emit(VehiclesLoaded(horses: horses, trailers: trailers));
      } catch (e) {
        emit(VehicleError('Failed to load vehicles.'));
      }
    });
  }
}
