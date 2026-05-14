import '../../data/models/daily_check_model.dart';

abstract class InspectionState {}
class InspectionInitial  extends InspectionState {}
class InspectionLoading  extends InspectionState {}
class InspectionSubmitSuccess extends InspectionState {}

class InspectionHistoryLoaded extends InspectionState {
  final List<DailyCheckModel> checks;
  InspectionHistoryLoaded(this.checks);
}

class InspectionError extends InspectionState {
  final String message;
  InspectionError(this.message);
}
