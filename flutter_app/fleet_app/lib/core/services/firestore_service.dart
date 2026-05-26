import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> docsToList(QuerySnapshot snap) =>
      snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();

  Map<String, dynamic> docToMap(DocumentSnapshot doc) =>
      {'id': doc.id, ...doc.data() as Map<String, dynamic>};
}
