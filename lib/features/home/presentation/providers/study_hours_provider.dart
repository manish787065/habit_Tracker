import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/hive_helper.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class StudyState {
  final double totalSeconds;
  final bool isTimerRunning;

  StudyState({required this.totalSeconds, required this.isTimerRunning});

  double get totalHours => totalSeconds / 3600;

  StudyState copyWith({double? totalSeconds, bool? isTimerRunning}) {
    return StudyState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
    );
  }
}

class StudyHoursNotifier extends StateNotifier<StudyState> {
  Timer? _timer;
  final Ref ref;

  StudyHoursNotifier(this.ref) : super(StudyState(totalSeconds: 0, isTimerRunning: false)) {
    _loadTodayHours();
  }

  void _loadTodayHours() {
    final box = HiveHelper.habits;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final double savedSeconds = box.get('study_hours_$today', defaultValue: 0.0);
    
    state = StudyState(totalSeconds: savedSeconds, isTimerRunning: false);
  }

  Future<void> _saveHours() async {
    final box = HiveHelper.habits;
    final today = DateTime.now().toIso8601String().split('T')[0];
    await box.put('study_hours_$today', state.totalSeconds);
    
    // Update index of days
    final List<String> daysIndex = List<String>.from(box.get('study_days_index', defaultValue: []));
    if (!daysIndex.contains(today)) {
      daysIndex.add(today);
      await box.put('study_days_index', daysIndex);
    }
  }

  void startTimer() {
    if (state.isTimerRunning) return; // Changed from state.isRunning to state.isTimerRunning for syntactic correctness
    state = state.copyWith(isTimerRunning: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newSeconds = state.totalSeconds + 1;
      
      // Award 10 points for every full hour (3600s)
      if (newSeconds % 3600 == 0) {
        ref.read(authProvider.notifier).addPoints(10);
      }
      
      state = state.copyWith(totalSeconds: newSeconds);
      if (state.totalSeconds % 10 == 0) {
        _saveHours();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isTimerRunning: false);
    _saveHours();
  }

  void addManualHours(double hours) {
    final secondsToAdd = hours * 3600;
    if (secondsToAdd + state.totalSeconds < 0) return;
    
    state = state.copyWith(totalSeconds: state.totalSeconds + secondsToAdd);
    _saveHours();
  }

  List<Map<String, dynamic>> getHistory() {
    final box = HiveHelper.habits;
    final List<String> daysIndex = List<String>.from(box.get('study_days_index', defaultValue: []));
    
    // Sort by most recent first
    daysIndex.sort((a, b) => b.compareTo(a));

    return daysIndex.map((date) {
      final double seconds = box.get('study_hours_$date', defaultValue: 0.0);
      return {
        'date': date,
        'hours': seconds / 3600,
      };
    }).toList();
  }

  List<double> getWeeklyData() {
    final box = HiveHelper.habits;
    final List<double> weeklyHours = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      
      if (i == 0) {
        // Today - use current state
        weeklyHours.add(state.totalHours);
      } else {
        final double seconds = box.get('study_hours_$dateStr', defaultValue: 0.0);
        weeklyHours.add(seconds / 3600);
      }
    }
    return weeklyHours;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final studyHoursProvider = StateNotifierProvider<StudyHoursNotifier, StudyState>((ref) {
  return StudyHoursNotifier(ref);
});
