import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/daily_check_model.dart';

class DriverDataSource {
  final FirestoreService _fs;
  DriverDataSource(this._fs);

  Future<Map<String, dynamic>> getHomeData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Active trip assigned to this driver
    Query tripsQuery = _fs.db.collection('trips')
        .where('status', isEqualTo: 'in_progress');
    if (uid != null) {
      tripsQuery = tripsQuery.where('driver_id', isEqualTo: uid);
    }
    final tripsSnap = await tripsQuery.limit(1).get();
    final activeTrip = tripsSnap.docs.isNotEmpty
        ? {'id': tripsSnap.docs.first.id, ...tripsSnap.docs.first.data() as Map<String, dynamic>}
        : null;

    // Vehicle assigned to this driver
    Map<String, dynamic>? vehicle;
    if (activeTrip != null && activeTrip['horse_id'] != null) {
      final vDoc = await _fs.db.collection('vehicles')
          .doc(activeTrip['horse_id'] as String).get();
      if (vDoc.exists) vehicle = _fs.docToMap(vDoc);
    }

    return {'active_trip': activeTrip, 'vehicle': vehicle};
  }

  Future<void> updateTripStatus(String tripId, String newStatus) async {
    final updates = <String, dynamic>{'status': newStatus};
    if (newStatus == 'in_progress') {
      updates['actual_start'] = DateTime.now().toIso8601String();
    } else if (newStatus == 'completed') {
      updates['actual_end'] = DateTime.now().toIso8601String();
    }
    await _fs.db.collection('trips').doc(tripId).update(updates);
  }

  Future<List<DailyCheckModel>> getDailyChecks() async {
    final snap = await _fs.db.collection('daily_checks')
        .orderBy('check_date', descending: true)
        .get();
    return snap.docs
        .map((d) => DailyCheckModel.fromJson({'id': d.id, ...d.data()}))
        .toList();
  }

  Future<void> submitDailyCheck(Map<String, dynamic> data) async {
    await _fs.db.collection('daily_checks').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<dynamic>> getMyTrips({String? statusFilter}) async {
    Query query = _fs.db.collection('trips');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) query = query.where('driver_id', isEqualTo: uid);
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    final snap = await query.get();
    return _fs.docsToList(snap);
  }
}
