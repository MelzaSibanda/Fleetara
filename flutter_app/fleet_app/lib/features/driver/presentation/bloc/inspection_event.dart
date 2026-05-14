abstract class InspectionEvent {}
class InspectionHistoryRequested extends InspectionEvent {}

class InspectionSubmitRequested extends InspectionEvent {
  final Map<String, dynamic> data;
  InspectionSubmitRequested(this.data);
}
