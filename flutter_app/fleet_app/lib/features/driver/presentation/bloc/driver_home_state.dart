abstract class DriverHomeState {}
class DriverHomeInitial extends DriverHomeState {}
class DriverHomeLoading extends DriverHomeState {}

class DriverHomeLoaded extends DriverHomeState {
  final Map<String, dynamic>? activeTrip;
  final Map<String, dynamic>? vehicle;
  DriverHomeLoaded({this.activeTrip, this.vehicle});
}

class DriverHomeError extends DriverHomeState {
  final String message;
  DriverHomeError(this.message);
}
