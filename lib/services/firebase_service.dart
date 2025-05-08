// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conference_app/models/user.dart';
import 'package:conference_app/utils/date_utils.dart'; // Add this import

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

  // Gets all upcoming talks (talks scheduled in the future)
  Future<List<Map<String, dynamic>>> getUpcomingTalks() async {
    try {
      final snapshot = await _firestore.collection(_talks).get();
      
      final List<Map<String, dynamic>> upcomingTalks = [];
      
      for (var doc in snapshot.docs) {
        final talk = {'id': doc.id, ...doc.data()};
        
        // Use the date utility to check if this event is in the past
        final String day = talk['day'] ?? '';
        final String time = talk['time'] ?? '';
        
        // Skip filtering if date or time is missing
        if (day.isEmpty || time.isEmpty) {
          upcomingTalks.add(talk); // Default to showing events with no date
          continue;
        }
        
        if (!ConferenceDateUtils.isEventInPast(day, time)) {
          upcomingTalks.add(talk);
        }
      }
      
      return upcomingTalks;
    } catch (e) {
      print('Error getting upcoming talks: $e');
      rethrow;
    }
  }

  // Gets past talks (talks that have already occurred)
  Future<List<Map<String, dynamic>>> getPastTalks() async {
    try {
      final snapshot = await _firestore.collection(_talks).get();
      
      final List<Map<String, dynamic>> pastTalks = [];
      
      for (var doc in snapshot.docs) {
        final talk = {'id': doc.id, ...doc.data()};
        
        // Use the date utility to check if this event is in the past
        final String day = talk['day'] ?? '';
        final String time = talk['time'] ?? '';
        
        // Skip filtering if date or time is missing
        if (day.isEmpty || time.isEmpty) {
          continue; // Don't include events with no date in past events
        }
        
        if (ConferenceDateUtils.isEventInPast(day, time)) {
          pastTalks.add(talk);
        }
      }
      
      return pastTalks;
    } catch (e) {
      print('Error getting past talks: $e');
      rethrow;
    }
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