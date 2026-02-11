import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/hive_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Habit Model
class Habit {
  final String id;
  final String title;
  final String frequency;
  final int iconCode;
  final List<DateTime> completedDays;

  Habit({
    required this.id,
    required this.title,
    this.frequency = 'Daily',
    this.iconCode = 57683,
    this.completedDays = const [],
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      frequency: map['frequency'] ?? 'Daily',
      iconCode: map['iconCode'] ?? 57683,
      completedDays: (map['completedDays'] as List?)
              ?.map((e) => DateTime.parse(e.toString()))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'frequency': frequency,
      'iconCode': iconCode,
      'completedDays': completedDays.map((e) => e.toIso8601String()).toList(),
    };
  }

  bool isCompletedToday() {
    final now = DateTime.now();
    return completedDays.any((date) =>
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day);
  }

  int get streak {
    if (completedDays.isEmpty) return 0;
    final sortedDays = completedDays.map((d) => DateTime(d.year, d.month, d.day)).toList()
      ..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int streakCount = 0;
    DateTime checkDate = todayDate;
    if (sortedDays.contains(checkDate)) {
      streakCount++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
       checkDate = checkDate.subtract(const Duration(days: 1));
       if (!sortedDays.contains(checkDate)) return 0;
    }
    while (sortedDays.contains(checkDate)) {
      streakCount++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streakCount;
  }
}

// State Notifier
class HabitNotifier extends StateNotifier<List<Habit>> {
  final Ref ref;
  StreamSubscription? _subscription;
  final _firestore = FirebaseFirestore.instance;

  HabitNotifier(this.ref) : super([]) {
    _init();
  }

  void _init() {
    // Listen to Auth state to start/stop Firestore sync
    ref.listen<User?>(authProvider, (previous, next) {
      if (next == null) {
        _subscription?.cancel();
        state = [];
      } else {
        _startSync(next.id);
      }
    }, fireImmediately: true);

    // Initial load from Hive for offline speed
    _loadFromHive();
  }

  void _loadFromHive() {
    final habitsData = HiveHelper.habits.get('habitsList', defaultValue: []);
    if (habitsData is List) {
      state = habitsData
          .map((e) => Habit.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  void _startSync(String userId) {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .snapshots()
        .listen((snapshot) {
      final habits = snapshot.docs.map((doc) => Habit.fromMap(doc.data() as Map<String, dynamic>)).toList();
      state = habits;
      _saveToHive(habits);
    });
  }

  Future<void> _saveToHive(List<Habit> habits) async {
    final habitsMap = habits.map((e) => e.toMap()).toList();
    await HiveHelper.habits.put('habitsList', habitsMap);
  }

  Future<void> addHabit(String title, {String frequency = 'Daily', int iconCode = 57683}) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newHabit = Habit(
      id: id,
      title: title,
      frequency: frequency,
      iconCode: iconCode,
    );

    await _firestore
        .collection('users')
        .doc(user.id)
        .collection('habits')
        .doc(id)
        .set(newHabit.toMap());
  }

  Future<void> toggleHabitCompletion(String id) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final habit = state.firstWhere((h) => h.id == id);
    final isCompleted = habit.isCompletedToday();

    List<DateTime> newCompletedDays;
    if (isCompleted) {
      final now = DateTime.now();
      newCompletedDays = habit.completedDays
          .where((date) =>
              !(date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day))
          .toList();
      ref.read(authProvider.notifier).deductPoints(5);
    } else {
      newCompletedDays = [...habit.completedDays, DateTime.now()];
      ref.read(authProvider.notifier).addPoints(5);
    }

    await _firestore
        .collection('users')
        .doc(user.id)
        .collection('habits')
        .doc(id)
        .update({'completedDays': newCompletedDays.map((e) => e.toIso8601String()).toList()});
  }

  Future<void> deleteHabit(String id) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.id)
        .collection('habits')
        .doc(id)
        .delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  return HabitNotifier(ref);
});
