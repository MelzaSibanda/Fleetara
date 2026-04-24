import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../data/trip_model.dart';

class TripDetailPage extends StatefulWidget {
  final int tripId;
  const TripDetailPage({super.key, required this.tripId});
  @override State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  TripModel? _trip;
  bool       _loading = true;

  @override
  void initState() { super.initState(); _loadTrip(); }

  Future<void> _loadTrip() async {
    try {
      final res = await sl<ApiClient>().dio.get('/trips/${widget.tripId}/');
      setState(() { _trip = TripModel.fromJson(res.data); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await sl<ApiClient>().dio.patch('/trips/${widget.tripId}/status/',
        data: {'status': newStatus});
      _loadTrip();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip $newStatus'), backgroundColor: AppTheme.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trip #${widget.tripId}')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _trip == null
          ? const Center(child: Text('Trip not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _trip!.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _trip!.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.circle, size: 10, color: _trip!.statusColor),
                    const SizedBox(width: 8),
                    Text(_trip!.statusLabel,
                      style: TextStyle(color: _trip!.statusColor, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 24),
                _section('Client',    _trip!.clientName, Icons.business),
                _section('Route',     '${_trip!.origin}  →  ${_trip!.destination}', Icons.route),
                _section('Cargo',     '${_trip!.cargoType} — ${_trip!.cargoDescription}', Icons.inventory_2),
                _section('Scheduled', _trip!.scheduledStart.length >= 16
                  ? _trip!.scheduledStart.substring(0, 16) : _trip!.scheduledStart,
                  Icons.calendar_today),
                const SizedBox(height: 32),
                if (_trip!.status == 'scheduled')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus('in_progress'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Trip'),
                  ),
                if (_trip!.status == 'in_progress') ...[
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus('completed'),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete Trip'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/fuel/add'),
                    icon: const Icon(Icons.local_gas_station),
                    label: const Text('Log Fuel Stop'),
                  ),
                ],
              ]),
            ),
    );
  }

  Widget _section(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ])),
      ]),
    );
  }
}
