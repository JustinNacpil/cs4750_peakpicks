import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tier_list.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('tierLists');

  // ── Load All ─────────────────────────────────────
  static Future<List<TierList>> loadAll() async {
    final snap = await _col
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs.map((d) => TierList.fromJson(d.data())).toList();
  }

  // ── Stream All (real-time) ────────────────────────
  static Stream<List<TierList>> streamAll() {
    return _col
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TierList.fromJson(d.data())).toList());
  }

  // ── Save Single ───────────────────────────────────
  static Future<void> saveSingle(TierList tl) async {
    tl.updatedAt = DateTime.now();
    tl.userId = _uid;
    await _col.doc(tl.id).set(tl.toJson());
  }

  // ── Delete ────────────────────────────────────────
  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
