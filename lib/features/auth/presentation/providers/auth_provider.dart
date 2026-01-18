import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/hive_helper.dart';

// User Model
class User {
  final String name;
  final String profession;
  final String username;
  final String password;
  final int points;
  final int dailyPoints;
  final String? lastActiveDate;

  User({
    required this.name,
    required this.profession,
    required this.username,
    required this.password,
    this.points = 0,
    this.dailyPoints = 0,
    this.lastActiveDate,
  });

  factory User.fromMap(Map<dynamic, dynamic> map) {
    return User(
      name: map['name'] ?? '',
      profession: map['profession'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      points: map['points'] ?? 0,
      dailyPoints: map['dailyPoints'] ?? 0,
      lastActiveDate: map['lastActiveDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profession': profession,
      'username': username,
      'password': password,
      'points': points,
      'dailyPoints': dailyPoints,
      'lastActiveDate': lastActiveDate,
    };
  }
  
  User copyWith({
    String? name,
    String? profession,
    String? username,
    String? password,
    int? points,
    int? dailyPoints,
    String? lastActiveDate,
  }) {
    return User(
      name: name ?? this.name,
      profession: profession ?? this.profession,
      username: username ?? this.username,
      password: password ?? this.password,
      points: points ?? this.points,
      dailyPoints: dailyPoints ?? this.dailyPoints,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
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
        _checkDailyReset();
      }
    }
  }

  void _checkDailyReset() {
    if (state == null) return;
    
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    if (state!.lastActiveDate != todayStr) {
      // It's a new day (or first run), reset daily points
      final updatedUser = state!.copyWith(dailyPoints: 0, lastActiveDate: todayStr);
      _saveUser(updatedUser);
    }
  }

  Future<bool> register(String name, String profession, String username, String password) async {
    final box = HiveHelper.user;
    final String userKey = 'user_$username';
    
    if (box.containsKey(userKey)) {
      return false; // User already exists
    }

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    final newUser = User(
      name: name, 
      profession: profession, 
      username: username,
      password: password,
      points: 0,
      dailyPoints: 0,
      lastActiveDate: todayStr,
    );
    
    await box.put(userKey, newUser.toMap());
    // Auto login after register? Or require login? Let's auto login for UX.
    await box.put('currentUser', newUser.toMap());
    state = newUser;
    return true;
  }

  Future<bool> login(String username, String password) async {
    final box = HiveHelper.user;
    final String userKey = 'user_$username';
    
    final userData = box.get(userKey);
    
    if (userData != null) {
      final user = User.fromMap(Map<String, dynamic>.from(userData));
      if (user.password == password) {
        await box.put('currentUser', user.toMap());
        state = user;
        _checkDailyReset();
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    final box = HiveHelper.user;
    await box.delete('currentUser');
    state = null;
  }

  Future<void> updateName(String newName) async {
    if (state == null) return;
    final updatedUser = state!.copyWith(name: newName);
    await _saveUser(updatedUser);
  }
  
  Future<void> addPoints(int amount) async {
    if (state == null) return;
    _checkDailyReset(); // Ensure day is correct before adding
    
    final updatedUser = state!.copyWith(
      points: state!.points + amount,
      dailyPoints: state!.dailyPoints + amount,
    );
    await _saveUser(updatedUser);
  }
  
  Future<void> deductPoints(int amount) async {
    if (state == null) return;
    _checkDailyReset(); // Ensure day is correct
    
    int newPoints = state!.points - amount;
    if (newPoints < 0) newPoints = 0;

    int newDailyPoints = state!.dailyPoints - amount;
    // Don't let daily points go below 0? Or allow it? 
    // Usually daily score shouldn't be negative unless penalizing current day's actions.
    // If user unchecks a habit from yesterday, should it affect today's daily score?
    // Probably yes, to prevent gaming. But maybe floor at 0.
    if (newDailyPoints < 0) newDailyPoints = 0;
    
    final updatedUser = state!.copyWith(
      points: newPoints,
      dailyPoints: newDailyPoints
    );
    await _saveUser(updatedUser);
  }
  
  Future<void> _saveUser(User user) async {
     final box = HiveHelper.user;
     final String userKey = 'user_${user.username}';
     await box.put(userKey, user.toMap()); // Update record
     await box.put('currentUser', user.toMap()); // Update current session
     state = user;
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});
