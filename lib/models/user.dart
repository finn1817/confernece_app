// lib/models/user.dart
// model we made for the users stored in Firebase db (at our 'users' collection)

class User {
  // unique ID (same as the Firebase doc ID)
  final String id;

  // username used for login
  final String username;

  // password (plain text as default sets to guest non-admin user for testing,
  // but the passwords and users are stored on firebase)
  final String password;

  // true if user is an admin (1) or false if user is not (0)
  final bool isAdmin;

  // constructor to make the User object
  User({
    required this.id,
    required this.username,
    required this.password,
    required this.isAdmin,
  });

  // creates a User from Firebase data + doc ID
  factory User.fromMap(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      username: data['username'] as String,
      password: data['password'] as String,
      isAdmin: (data['isAdmin'] as int) == 1, // stored as 1 or 0
    );
  }

  // converts this User into a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'isAdmin': isAdmin ? 1 : 0, // stored as int in Firebase, not a string
    };
  }
}
