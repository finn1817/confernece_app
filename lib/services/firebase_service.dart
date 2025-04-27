import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'talks';

  // Get all talks
  Stream<List<Map<String, dynamic>>> getTalks() {
    return _firestore.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Get upcoming talks (talks with timestamps in the future)
  Future<List<Map<String, dynamic>>> getUpcomingTalks() async {
    try {
      // Get current time for comparison
      final now = DateTime.now();
      
      final snapshot = await _firestore.collection(collection).get();
      
      // Filter and sort upcoming talks
      final upcomingTalks = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // For now, just return all talks as "upcoming"
      // In a real implementation, you would filter based on date/time fields
      // When you add date fields to your talk objects, you can implement proper filtering
      
      return upcomingTalks;
    } catch (e) {
      print('Error getting upcoming talks: $e');
      return [];
    }
  }

  // Add a new talk
  Future<DocumentReference> addTalk(Map<String, dynamic> talk) {
    // Remove the id if it exists before adding to Firestore
    final Map<String, dynamic> talkToAdd = Map<String, dynamic>.from(talk);
    talkToAdd.remove('id');
    return _firestore.collection(collection).add(talkToAdd);
  }

  // Update an existing talk
  Future<void> updateTalk(String id, Map<String, dynamic> talk) {
    // Remove the id if it exists before updating in Firestore
    final Map<String, dynamic> talkToUpdate = Map<String, dynamic>.from(talk);
    talkToUpdate.remove('id');
    return _firestore.collection(collection).doc(id).update(talkToUpdate);
  }

  // Delete a talk
  Future<void> deleteTalk(String id) {
    return _firestore.collection(collection).doc(id).delete();
  }
}