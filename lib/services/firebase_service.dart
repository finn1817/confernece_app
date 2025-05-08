// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conference_app/models/user.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // collection names
  static const _talks   = 'talks';
  static const _users   = 'users';

  // ── TALKS CRUD ────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getTalks() {
    return _firestore.collection(_talks).snapshots().map((snap) {
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getUpcomingTalks() async {
    final snap = await _firestore.collection(_talks).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<DocumentReference> addTalk(Map<String, dynamic> talk) {
    final data = Map<String, dynamic>.from(talk)..remove('id');
    return _firestore.collection(_talks).add(data);
  }

  Future<void> updateTalk(String id, Map<String, dynamic> talk) {
    final data = Map<String, dynamic>.from(talk)..remove('id');
    return _firestore.collection(_talks).doc(id).update(data);
  }

  Future<void> deleteTalk(String id) {
    return _firestore.collection(_talks).doc(id).delete();
  }

  // ── USERS CRUD & AUTH ─────────────────────────────────────────────────────

  Stream<List<User>> getUsers() {
    return _firestore.collection(_users).snapshots().map((snap) {
      return snap.docs
        .map((d) => User.fromMap(d.id, d.data()))
        .toList();
    });
  }

  Future<User?> getUserByUsername(String username) async {
    final q = await _firestore
      .collection(_users)
      .where('username', isEqualTo: username)
      .limit(1)
      .get();
    if (q.docs.isEmpty) return null;
    return User.fromMap(q.docs.first.id, q.docs.first.data());
  }

  Future<void> addUser(User u) {
    return _firestore.collection(_users).add(u.toMap());
  }

  Future<void> updateUserRole(String id, bool isAdmin) {
    return _firestore.collection(_users).doc(id).update({'isAdmin': isAdmin ? 1 : 0});
  }

  Future<void> deleteUser(String id) {
    return _firestore.collection(_users).doc(id).delete();
  }

  Future<User?> authenticate(String username, String password) async {
    final u = await getUserByUsername(username);
    if (u != null && u.password == password) {
      return u;
    }
    return null;
  }
}
