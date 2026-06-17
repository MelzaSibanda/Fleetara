import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import 'driver_profile_page.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({super.key});
  @override State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  List   _drivers   = [];
  List   _all       = [];
  bool   _loading   = true;
  String _filter    = 'all'; // 'all' | 'active' | 'inactive'
  final _fs = sl<FirestoreService>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _fs.db.collection('users')
          .where('role', isEqualTo: 'driver').get();
      _all = _fs.docsToList(snap)
        ..sort((a, b) {
          final na = ('${a['first_name'] ?? ''} ${a['last_name'] ?? ''}').trim();
          final nb = ('${b['first_name'] ?? ''} ${b['last_name'] ?? ''}').trim();
          return na.compareTo(nb);
        });
      _applyFilter();
      setState(() => _loading = false);
    } catch (_) { setState(() => _loading = false); }
  }

  void _applyFilter() {
    setState(() {
      _drivers = _filter == 'all'
          ? List.from(_all)
          : _all.where((d) {
              final active = d['is_active'] ?? true;
              return _filter == 'active' ? active : !active;
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Drivers',
      child: Column(children: [

        // ── Filter bar ──────────────────────────────────────────────────
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            for (final f in ['all', 'active', 'inactive']) ...[
              GestureDetector(
                onTap: () { setState(() => _filter = f); _applyFilter(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _filter == f
                        ? AppTheme.primary.withValues(alpha: 0.10)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _filter == f
                          ? AppTheme.primary.withValues(alpha: 0.45)
                          : AppTheme.border,
                      width: 0.6)),
                  child: Text(
                    f == 'all' ? 'All' : '${f[0].toUpperCase()}${f.substring(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _filter == f ? FontWeight.w600 : FontWeight.w400,
                      color: _filter == f ? AppTheme.primary : AppTheme.textMuted)),
                ),
              ),
            ],
            const Spacer(),
            Text('${_drivers.length} driver${_drivers.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ]),
        ),

        // ── List ────────────────────────────────────────────────────────
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2))
            : _drivers.isEmpty
              ? EmptyState(
                  icon: Icons.people_outlined,
                  title: 'No drivers',
                  subtitle: _filter == 'all'
                      ? 'Registered drivers will appear here.'
                      : 'No $_filter drivers found.')
              : RListBody(
                  twoColumn: true,
                  onRefresh: _load,
                  cards: _drivers.map((d) => _DriverCard(
                    driver: d,
                    onTap: () async {
                      await Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            DriverProfilePage(userId: d['id'] as String)));
                      _load();
                    },
                  )).toList(),
                ),
        ),
      ]),
    );
  }
}

// ── Driver card ────────────────────────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  final Map          driver;
  final VoidCallback onTap;
  const _DriverCard({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name    = ('${driver['first_name'] ?? ''} ${driver['last_name'] ?? ''}').trim();
    final email   = driver['email']          ?? '';
    final phone   = driver['phone']          ?? '';
    final license = driver['license_number'] ?? '';
    final expiry  = driver['license_expiry'] ?? '';
    final active  = driver['is_active']      ?? true;
    final photo   = driver['profile_photo']  as String?;

    // Warn if licence is expiring within 30 days or expired
    Color? expiryColor;
    if (expiry.isNotEmpty) {
      try {
        final exp  = DateTime.parse(expiry);
        final days = exp.difference(DateTime.now()).inDays;
        if (days < 0)   { expiryColor = AppTheme.rose; }
        else if (days <= 30) { expiryColor = AppTheme.amber; }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration,
        child: Row(children: [

          DriverAvatar(photoBase64: photo, name: name.isNotEmpty ? name : email, size: 50),
          const SizedBox(width: 12),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(name.isNotEmpty ? name : email,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis)),
              StatusPill(
                label:  active ? 'Active' : 'Inactive',
                color:  active ? AppTheme.emerald : AppTheme.textMuted),
            ]),
            const SizedBox(height: 3),
            if (phone.isNotEmpty)
              Text(phone, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            if (license.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.credit_card_outlined, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(license,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                if (expiry.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.event_outlined, size: 12,
                    color: expiryColor ?? AppTheme.textMuted),
                  const SizedBox(width: 3),
                  Text(expiry,
                    style: TextStyle(fontSize: 11,
                      color: expiryColor ?? AppTheme.textMuted,
                      fontWeight: expiryColor != null ? FontWeight.w600 : FontWeight.normal)),
                ],
              ]),
            ],
          ])),

          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
        ]),
      ),
    );
  }
}
