import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/hive_helper.dart';

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
    this.iconCode = 57683, // Icons.book code point (approx default)
    this.completedDays = const [],
  });

  factory Habit.fromMap(Map<dynamic, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
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
      ..sort((a, b) => b.compareTo(a)); // Newest first

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    int streakCount = 0;
    DateTime checkDate = todayDate;

    // Check if today is completed
    if (sortedDays.contains(checkDate)) {
      streakCount++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      // If not, check if yesterday was completed (streak maintained but not extended yet)
      // Actually, standard streak logic: if you missed today (so far), streak is from yesterday.
      // If you missed yesterday too, streak is 0.
       checkDate = checkDate.subtract(const Duration(days: 1));
       if (!sortedDays.contains(checkDate)) {
         return 0; // Missed yesterday and today
       }
    }

    // Standard loop
    while (sortedDays.contains(checkDate)) {
      streakCount++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streakCount;
  }
}

// State Notifier
class HabitNotifier extends StateNotifier<List<Habit>> {
  HabitNotifier() : super([]) {
    _loadHabits();
  }

  void _loadHabits() {
    final box = HiveHelper.habits;
    final habitsData = box.get('habitsList', defaultValue: []);
    if (habitsData is List) {
      state = habitsData
          .map((e) => Habit.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> _saveHabits() async {
    final box = HiveHelper.habits;
    final habitsMap = state.map((e) => e.toMap()).toList();
    await box.put('habitsList', habitsMap);
  }

  Future<void> addHabit(String title, {String frequency = 'Daily', int iconCode = 57683}) async {
    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      frequency: frequency,
      iconCode: iconCode,
    );
    state = [...state, newHabit];
    await _saveHabits();
  }

  Future<void> toggleHabitCompletion(String id) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    state = state.map((habit) {
      if (habit.id == id) {
        final isCompleted = habit.completedDays.any((date) =>
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day);

        List<DateTime> newCompletedDays;
        if (isCompleted) {
          newCompletedDays = habit.completedDays
              .where((date) =>
                  !(date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day))
              .toList();
        } else {
          newCompletedDays = [...habit.completedDays, today];
        }
        return Habit(
            id: habit.id,
            title: habit.title,
            completedDays: newCompletedDays);
      }
      return habit;
    }).toList();
    await _saveHabits();
  }
  Future<void> deleteHabit(String id) async {
    state = state.where((habit) => habit.id != id).toList();
    await _saveHabits();
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  return HabitNotifier();
});
