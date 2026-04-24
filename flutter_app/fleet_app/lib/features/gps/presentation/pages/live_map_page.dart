import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});
  @override State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  List   _liveData = [];
  bool   _loading  = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final res = await sl<ApiClient>().dio.get('/gps/live/');
      setState(() { _liveData = res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Live Tracking',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
      ],
      child: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.primary.withValues(alpha: 0.08),
              child: Row(children: [
                Container(width: 10, height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.success, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('${_liveData.length} active trip${_liveData.length != 1 ? 's' : ''} on the road',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Text('Auto-refreshes every 30s',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
            Expanded(
              child: _liveData.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.map_outlined, size: 72, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No active trips', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text('Live driver locations will appear here\nwhen trips are in progress.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _liveData.length,
                    itemBuilder: (_, i) {
                      final d = _liveData[i];
                      final ts = (d['timestamp'] ?? '').toString();
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.local_shipping, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(d['driver'] ?? '',
                                  style: Theme.of(context).textTheme.titleMedium),
                                Text(d['horse'] ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(children: [
                                  Container(width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.success, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  const Text('Live', style: TextStyle(
                                    fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.route, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(child: Text(
                                '${d['origin']}  →  ${d['destination']}',
                                style: const TextStyle(fontSize: 13))),
                            ]),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.location_on, size: 14, color: AppTheme.accent),
                              const SizedBox(width: 6),
                              Text('Lat: ${d['latitude']},  Lon: ${d['longitude']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (d['speed_kmh'] != null) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.speed, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${d['speed_kmh']} km/h',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ]),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.access_time, size: 13, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('Last ping: ${ts.length >= 19 ? ts.substring(0, 19) : ts}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
            ),
          ]),
    );
  }
}
