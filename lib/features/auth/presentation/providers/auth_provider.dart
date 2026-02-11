import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/data/hive_helper.dart';

// User Model
class User {
  final String id;
  final String name;
  final String profession;
  final String username;
  final int points;
  final int dailyPoints;
  final String? lastActiveDate;

  User({
    required this.id,
    required this.name,
    required this.profession,
    required this.username,
    this.points = 0,
    this.dailyPoints = 0,
    this.lastActiveDate,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      profession: map['profession'] ?? '',
      username: map['username'] ?? '',
      points: map['points'] ?? 0,
      dailyPoints: map['dailyPoints'] ?? 0,
      lastActiveDate: map['lastActiveDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profession': profession,
      'username': username,
      'points': points,
      'dailyPoints': dailyPoints,
      'lastActiveDate': lastActiveDate,
    };
  }
  
  User copyWith({
    String? id,
    String? name,
    String? profession,
    String? username,
    int? points,
    int? dailyPoints,
    String? lastActiveDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      profession: profession ?? this.profession,
      username: username ?? this.username,
      points: points ?? this.points,
      dailyPoints: dailyPoints ?? this.dailyPoints,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}

// State Notifier
class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    _init();
  }

  final _auth = auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  void _init() {
    // Listen for auth changes
    _auth.authStateChanges().listen((authUser) async {
      if (authUser == null) {
        state = null;
        await HiveHelper.user.delete('currentUser');
      } else {
        await _fetchAndSyncUser(authUser.uid);
      }
    });

    // Initial load from Hive for instant UI
    final userData = HiveHelper.user.get('currentUser');
    if (userData != null) {
      state = User.fromMap(Map<String, dynamic>.from(userData));
    }
  }

  Future<void> _fetchAndSyncUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      // Guard: If the user has signed out or changed during this async fetch, abort.
      if (_auth.currentUser?.uid != uid) {
        print("Fetch aborted: User switched or logged out during sync.");
        return;
      }

      User user;
      if (doc.exists) {
        user = User.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        // Handle new user creation (e.g., from Google Sign-In)
        final authUser = _auth.currentUser;
        user = User(
          id: uid,
          name: authUser?.displayName ?? 'New User',
          profession: 'Student', // Default
          username: authUser?.email?.split('@')[0] ?? 'user',
          points: 0,
          dailyPoints: 0,
          lastActiveDate: "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}",
        );
        // Save to Firestore in background
        _firestore.collection('users').doc(uid).set(user.toMap());
      }
      
      state = user;
      await HiveHelper.user.put('currentUser', user.toMap());
      _checkDailyReset();
    } catch (e) {
      print("Error fetching/syncing user: $e");
    }
  }

  void _checkDailyReset() {
    if (state == null) return;
    
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    if (state!.lastActiveDate != todayStr) {
      final updatedUser = state!.copyWith(dailyPoints: 0, lastActiveDate: todayStr);
      _saveUser(updatedUser);
    }
  }

  Future<bool> register(String name, String profession, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final newUser = User(
        id: uid,
        name: name,
        profession: profession,
        username: email.split('@')[0],
        points: 0,
        dailyPoints: 0,
        lastActiveDate: "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}",
      );

      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      state = newUser;
      await HiveHelper.user.put('currentUser', newUser.toMap());
      return true;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final authUser = userCredential.user!;

      // Profile creation for new users is handled in _init's authStateChanges listener
      // or we can do it here optimistically. However, to reduce lag, we return true 
      // as soon as the account is linked.
      
      return true;
    } catch (e) {
      print("Google sign-in error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print("Starting Logout process...");
      // 1. Clear state FIRST to trigger UI change
      state = null;

      // 2. Clear local storage
      await HiveHelper.user.delete('currentUser');

      // 3. Background sign-outs
      _googleSignIn.signOut();
      _auth.signOut();
      
      print("Logout process completed locally.");
    } catch (e) {
      print("Logout error: $e");
      state = null; // Decisively logout even on error
    }
  }

  Future<void> updateName(String newName) async {
    if (state == null) return;
    final updatedUser = state!.copyWith(name: newName);
    await _saveUser(updatedUser);
  }
  
  Future<void> addPoints(int amount) async {
    if (state == null) return;
    _checkDailyReset();
    
    final updatedUser = state!.copyWith(
      points: state!.points + amount,
      dailyPoints: state!.dailyPoints + amount,
    );
    await _saveUser(updatedUser);
  }
  
  Future<void> deductPoints(int amount) async {
    if (state == null) return;
    _checkDailyReset();
    
    int newPoints = (state!.points - amount).clamp(0, 999999);
    int newDailyPoints = (state!.dailyPoints - amount).clamp(0, 999999);
    
    final updatedUser = state!.copyWith(
      points: newPoints,
      dailyPoints: newDailyPoints
    );
    await _saveUser(updatedUser);
  }
  
  Future<void> _saveUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      state = user;
      await HiveHelper.user.put('currentUser', user.toMap());
    } catch (e) {
      print("Error saving user: $e");
    }
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});
