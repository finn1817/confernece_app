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
      final snapshot = await _firestore.collection(collection).get();
      
      // Get all talks
      final upcomingTalks = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // For now, just return all talks as "upcoming"
      // In a real implementation, you would filter based on date/time fields
      
      return upcomingTalks;
    } catch (e) {
      print('Error getting upcoming talks: $e');
      return [];
    }
  }

  // Get talks filtered by attendee
  Future<List<Map<String, dynamic>>> getTalksByAttendee(String attendee) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      
      // Get all talks and filter by attendee
      final talks = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          })
          .where((talk) {
            if (talk.containsKey('attendees') && talk['attendees'] != null) {
              String attendeesStr = talk['attendees'] as String;
              List<String> attendeesList = attendeesStr.split(',').map((a) => a.trim()).toList();
              return attendeesList.contains(attendee);
            }
            return false;
          })
          .toList();
      
      return talks;
    } catch (e) {
      print('Error getting talks by attendee: $e');
      return [];
    }
  }

  // Add a new talk
  Future<DocumentReference> addTalk(Map<String, dynamic> talk) {
    // Remove the id if it exists before adding to Firestore
    final Map<String, dynamic> talkToAdd = Map<String, dynamic>.from(talk);
    talkToAdd.remove('id');
    
    // Ensure attendees field is properly formatted
    if (talkToAdd.containsKey('attendees')) {
      String attendeesStr = talkToAdd['attendees'] as String;
      List<String> attendeesList = attendeesStr.split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();
      talkToAdd['attendees'] = attendeesList.join(', ');
    }
    
    return _firestore.collection(collection).add(talkToAdd);
  }

  // Update an existing talk
  Future<void> updateTalk(String id, Map<String, dynamic> talk) {
    // Remove the id if it exists before updating in Firestore
    final Map<String, dynamic> talkToUpdate = Map<String, dynamic>.from(talk);
    talkToUpdate.remove('id');
    
    // Ensure attendees field is properly formatted
    if (talkToUpdate.containsKey('attendees')) {
      String attendeesStr = talkToUpdate['attendees'] as String;
      List<String> attendeesList = attendeesStr.split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();
      talkToUpdate['attendees'] = attendeesList.join(', ');
    }
    
    return _firestore.collection(collection).doc(id).update(talkToUpdate);
  }

  // Delete a talk
  Future<void> deleteTalk(String id) {
    return _firestore.collection(collection).doc(id).delete();
  }
  
  // Get unique attendees across all talks
  Future<List<String>> getUniqueAttendees() async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      
      // Extract attendees from all talks
      Set<String> uniqueAttendees = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('attendees') && data['attendees'] != null) {
          String attendeesStr = data['attendees'] as String;
          List<String> attendeesList = attendeesStr.split(',')
              .map((a) => a.trim())
              .where((a) => a.isNotEmpty)
              .toList();
          uniqueAttendees.addAll(attendeesList);
        }
      }
      
      return uniqueAttendees.toList()..sort();
    } catch (e) {
      print('Error getting unique attendees: $e');
      return [];
    }
  }
}