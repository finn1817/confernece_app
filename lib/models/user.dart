// lib/models/user.dart

class User {
  final String id;
  final String username;
  final String password;    // plaintext for now
  final bool isAdmin;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.isAdmin,
  });

  factory User.fromMap(String id, Map<String, dynamic> data) {
    return User(
      id:       id,
      username: data['username'] as String,
      password: data['password'] as String,
      isAdmin:  (data['isAdmin'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'isAdmin':  isAdmin ? 1 : 0,
    };
  }
}
