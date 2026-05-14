import '../../../../core/network/api_client.dart';
import '../models/daily_check_model.dart';

class DriverDataSource {
  final ApiClient _client;
  DriverDataSource(this._client);

  Future<Map<String, dynamic>> getHomeData() async {
    final tripsRes   = await _client.dio.get('/trips/', queryParameters: {'status': 'in_progress'});
    final vehicleRes = await _client.dio.get('/vehicles/driver/');

    final tripsList = tripsRes.data['results'] ?? tripsRes.data;
    final activeTrip = (tripsList as List).isNotEmpty ? tripsList.first : null;

    return {
      'active_trip': activeTrip,
      'vehicle':     vehicleRes.data,
    };
  }

  Future<void> updateTripStatus(int tripId, String newStatus) async {
    await _client.dio.patch('/trips/$tripId/status/', data: {'status': newStatus});
  }

  Future<List<DailyCheckModel>> getDailyChecks() async {
    final res  = await _client.dio.get('/daily-checks/');
    final list = res.data['results'] ?? res.data;
    return (list as List).map<DailyCheckModel>((j) => DailyCheckModel.fromJson(j)).toList();
  }

  Future<void> submitDailyCheck(Map<String, dynamic> data) async {
    await _client.dio.post('/daily-checks/', data: data);
  }

  Future<List<dynamic>> getMyTrips({String? statusFilter}) async {
    final params = <String, dynamic>{};
    if (statusFilter != null && statusFilter != 'all') params['status'] = statusFilter;
    final res  = await _client.dio.get('/trips/', queryParameters: params.isNotEmpty ? params : null);
    return res.data['results'] ?? res.data;
  }
}
