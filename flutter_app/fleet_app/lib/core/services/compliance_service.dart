import 'package:flutter/material.dart';
import 'firestore_service.dart';

class ComplianceAlert {
  final String vehicleId;
  final String vehicleReg;
  final String type;       // 'license', 'insurance', 'service'
  final String message;
  final String severity;   // 'expired', 'critical', 'warning', 'info'
  final int    daysRemaining; // negative = already expired; for service = km remaining

  const ComplianceAlert({
    required this.vehicleId,
    required this.vehicleReg,
    required this.type,
    required this.message,
    required this.severity,
    required this.daysRemaining,
  });

  Color get color {
    switch (severity) {
      case 'expired':  return const Color(0xFFEF4444);
      case 'critical': return const Color(0xFFEF4444);
      case 'warning':  return const Color(0xFFF59E0B);
      default:         return const Color(0xFF3B82F6);
    }
  }

  IconData get icon {
    switch (type) {
      case 'license':   return Icons.badge_outlined;
      case 'insurance': return Icons.security_outlined;
      case 'service':   return Icons.build_circle_outlined;
      default:          return Icons.warning_amber_rounded;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'license':   return 'Licence Disc';
      case 'insurance': return 'Insurance';
      case 'service':   return 'Service Due';
      default:          return type;
    }
  }
}

class ComplianceService {
  final FirestoreService _fs;
  ComplianceService(this._fs);

  Future<List<ComplianceAlert>> checkAll() async {
    final snap    = await _fs.db.collection('vehicles').get();
    final vehicles = _fs.docsToList(snap);
    final alerts  = <ComplianceAlert>[];
    final now     = DateTime.now().toUtc();

    for (final v in vehicles) {
      final reg = v['registration_number']?.toString() ?? '';
      final id  = v['id']?.toString() ?? '';

      // ── Licence disc ───────────────────────────────────────────────────
      final licStr = v['license_expiry']?.toString() ?? '';
      if (licStr.isNotEmpty) {
        final expiry = _parseDate(licStr);
        if (expiry != null) {
          final days = expiry.difference(now).inDays;
          if (days <= 90) {
            final sev = days <= 0 ? 'expired'
                : days <= 14 ? 'critical'
                : days <= 30 ? 'warning' : 'info';
            alerts.add(ComplianceAlert(
              vehicleId:      id,
              vehicleReg:     reg,
              type:           'license',
              daysRemaining:  days,
              severity:       sev,
              message:        days <= 0
                  ? 'Licence disc EXPIRED ($licStr)'
                  : 'Licence disc expires in $days day${days == 1 ? '' : 's'} ($licStr)',
            ));
          }
        }
      }

      // ── Insurance ──────────────────────────────────────────────────────
      final insStr = v['insurance_expiry']?.toString() ?? '';
      if (insStr.isNotEmpty) {
        final expiry = _parseDate(insStr);
        if (expiry != null) {
          final days = expiry.difference(now).inDays;
          if (days <= 30) {
            alerts.add(ComplianceAlert(
              vehicleId:     id,
              vehicleReg:    reg,
              type:          'insurance',
              daysRemaining: days,
              severity:      days <= 0 ? 'expired' : 'critical',
              message:       days <= 0
                  ? 'Insurance EXPIRED — vehicle must not operate ($insStr)'
                  : 'Insurance expires in $days day${days == 1 ? '' : 's'} — renew immediately ($insStr)',
            ));
          }
        }
      }

      // ── Service reminder (alert at 5 000 km before next service) ───────
      final odometer    = (v['odometer']         as num?)?.toInt() ?? 0;
      final nextService = (v['next_service_km']   as num?)?.toInt() ?? 0;
      final kmUntil     = nextService - odometer;
      if (nextService > 0 && kmUntil <= 5000) {
        final sev = kmUntil <= 0 ? 'expired'
            : kmUntil <= 1000 ? 'critical' : 'warning';
        alerts.add(ComplianceAlert(
          vehicleId:     id,
          vehicleReg:    reg,
          type:          'service',
          daysRemaining: kmUntil,
          severity:      sev,
          message:       kmUntil <= 0
              ? 'Service OVERDUE — ${(-kmUntil)} km past service interval'
              : 'Service due in $kmUntil km (at $nextService km)',
        ));
      }
    }

    // Sort: expired first, then by days remaining ascending
    alerts.sort((a, b) {
      final oa = _severityOrder(a.severity);
      final ob = _severityOrder(b.severity);
      if (oa != ob) return oa.compareTo(ob);
      return a.daysRemaining.compareTo(b.daysRemaining);
    });
    return alerts;
  }

  DateTime? _parseDate(String s) {
    // Accepts: YYYY-MM-DD or YYYY-MM-DDTHH:mm:ss
    try { return DateTime.parse(s.length > 10 ? s.substring(0, 10) : s); } catch (_) { return null; }
  }

  int _severityOrder(String s) {
    switch (s) {
      case 'expired':  return 0;
      case 'critical': return 1;
      case 'warning':  return 2;
      default:         return 3;
    }
  }
}
