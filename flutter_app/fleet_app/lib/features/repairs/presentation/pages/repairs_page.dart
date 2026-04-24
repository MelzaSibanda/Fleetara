import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class RepairsPage extends StatefulWidget {
  const RepairsPage({super.key});
  @override State<RepairsPage> createState() => _RepairsPageState();
}

class _RepairsPageState extends State<RepairsPage> {
  List _repairs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await sl<ApiClient>().dio.get('/repairs/');
      setState(() { _repairs = res.data['results'] ?? res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'critical': return AppTheme.error;
      case 'high':     return AppTheme.warning;
      case 'medium':   return AppTheme.accent;
      default:         return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Repairs',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/repairs/add'),
        backgroundColor: AppTheme.error,
        icon: const Icon(Icons.report_problem, color: Colors.white),
        label: const Text('Report Issue', style: TextStyle(color: Colors.white)),
      ),
      child: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _repairs.isEmpty
              ? const Center(child: Text('No repairs reported'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _repairs.length,
                  itemBuilder: (_, i) {
                    final r  = _repairs[i];
                    final pc = _priorityColor(r['priority'] ?? 'low');
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(r['title'] ?? '',
                              style: Theme.of(context).textTheme.titleMedium)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: pc.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(r['priority'] ?? '',
                                style: TextStyle(fontSize: 12,
                                  color: pc, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Text(r['description'] ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Icon(Icons.circle, size: 8, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(r['status'] ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const Spacer(),
                            Text((r['reported_at'] ?? '').toString().length >= 10
                              ? (r['reported_at'] ?? '').toString().substring(0, 10) : '',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
          ),
    );
  }
}
