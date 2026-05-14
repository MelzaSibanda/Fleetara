import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../../../../core/utils/responsive.dart';

class TyresPage extends StatefulWidget {
  const TyresPage({super.key});
  @override State<TyresPage> createState() => _TyresPageState();
}

class _TyresPageState extends State<TyresPage> {
  List _tyres   = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await sl<ApiClient>().dio.get('/tyres/');
      setState(() { _tyres = res.data['results'] ?? res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _conditionColor(String condition) {
    switch (condition) {
      case 'good':     return AppTheme.success;
      case 'worn':     return AppTheme.warning;
      case 'critical': return AppTheme.error;
      default:         return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Tyres',
      child: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _tyres.isEmpty
              ? const Center(child: Text('No tyres recorded'))
              : ListView.builder(
                  padding: Responsive.pagePadding(context),
                  itemCount: _tyres.length,
                  itemBuilder: (_, i) {
                    final t    = _tyres[i];
                    final cond = t['condition'] ?? 'good';
                    final cc   = _conditionColor(cond);
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: cc.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.tire_repair, color: cc),
                        ),
                        title: Text('${t['position']} — ${t['brand'] ?? 'Unknown brand'}'),
                        subtitle: Text('Size: ${t['size'] ?? '—'} • '
                          'Installed at ${t['installed_km']} km'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cc.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cond,
                            style: TextStyle(fontSize: 11,
                              color: cc, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }
}
