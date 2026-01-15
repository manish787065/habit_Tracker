import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/hive_helper.dart';

// User Model
class User {
  final String name;
  final String profession;
  final String username;

  User({required this.name, required this.profession, required this.username});

  factory User.fromMap(Map<dynamic, dynamic> map) {
    return User(
      name: map['name'] ?? '',
      profession: map['profession'] ?? '',
      username: map['username'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profession': profession,
      'username': username,
    };
  }
}

// State Notifier
class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    _loadUser();
  }

  void _loadUser() {
    final box = HiveHelper.user;
    if (box.isNotEmpty) {
      final userData = box.get('currentUser');
      if (userData != null) {
        state = User.fromMap(Map<String, dynamic>.from(userData));
      }
    }
  }

  Future<void> login(String name, String profession, String username) async {
    final newUser = User(name: name, profession: profession, username: username);
    final box = HiveHelper.user;
    await box.put('currentUser', newUser.toMap());
    state = newUser;
  }

  Future<void> logout() async {
    final box = HiveHelper.user;
    await box.delete('currentUser');
    state = null;
  }

  Future<void> updateName(String newName) async {
    if (state == null) return;
    final updatedUser = User(
      name: newName,
      profession: state!.profession,
      username: state!.username,
    );
    final box = HiveHelper.user;
    await box.put('currentUser', updatedUser.toMap());
    state = updatedUser;
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});
