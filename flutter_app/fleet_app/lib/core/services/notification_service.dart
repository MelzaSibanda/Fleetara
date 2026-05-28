import 'firestore_service.dart';

class NotificationService {
  final FirestoreService _fs;
  NotificationService(this._fs);

  Future<void> _send(String uid, String type, String title, String body,
      {String actor = '', Map<String, dynamic>? data}) async {
    await _fs.db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .add({
      'type':       type,
      'title':      title,
      'body':       body,
      'actor':      actor,
      'data':       data ?? {},
      'is_read':    false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> sendToManagers(String type, String title, String body,
      {String actor = '', Map<String, dynamic>? data}) async {
    try {
      final snap = await _fs.db
          .collection('users')
          .where('role', whereIn: ['fleet_manager', 'owner', 'admin'])
          .get();
      await Future.wait(snap.docs.map((d) =>
          _send(d.id, type, title, body, actor: actor, data: data)));
    } catch (_) {}
  }

  Future<void> sendToUser(String uid, String type, String title, String body,
      {String actor = '', Map<String, dynamic>? data}) async {
    if (uid.isEmpty) return;
    try {
      await _send(uid, type, title, body, actor: actor, data: data);
    } catch (_) {}
  }

  Stream<int> unreadCountStream(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    return _fs.db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<List<Map<String, dynamic>>> notificationsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _fs.db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final item = Map<String, dynamic>.from(d.data());
              item['id'] = d.id;
              return item;
            }).toList());
  }

  Future<void> markRead(String uid, String notifId) async {
    try {
      await _fs.db
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc(notifId)
          .update({'is_read': true});
    } catch (_) {}
  }

  Future<void> markAllRead(String uid) async {
    try {
      final snap = await _fs.db
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .where('is_read', isEqualTo: false)
          .get();
      final batch = _fs.db.batch();
      for (final d in snap.docs) {
        batch.update(d.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> deleteNotification(String uid, String notifId) async {
    try {
      await _fs.db
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc(notifId)
          .delete();
    } catch (_) {}
  }

  Future<void> clearAll(String uid) async {
    try {
      final snap = await _fs.db
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .get();
      final batch = _fs.db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (_) {}
  }
}
