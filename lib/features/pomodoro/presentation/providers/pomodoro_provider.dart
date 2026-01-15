import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/hive_helper.dart';

enum PomodoroPhase { work, breakTime }

class PomodoroState {
  final int remainingSeconds;
  final PomodoroPhase phase;
  final bool isRunning;
  final int currentCycle;
  final int totalCycles;
  final int workDurationMinutes;
  final int breakDurationMinutes;

  PomodoroState({
    required this.remainingSeconds,
    this.phase = PomodoroPhase.work,
    this.isRunning = false,
    this.currentCycle = 1,
    this.totalCycles = 4, // Default sets
    this.workDurationMinutes = 25,
    this.breakDurationMinutes = 5,
  });

  PomodoroState copyWith({
    int? remainingSeconds,
    PomodoroPhase? phase,
    bool? isRunning,
    int? currentCycle,
    int? totalCycles,
    int? workDurationMinutes,
    int? breakDurationMinutes,
  }) {
    return PomodoroState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      phase: phase ?? this.phase,
      isRunning: isRunning ?? this.isRunning,
      currentCycle: currentCycle ?? this.currentCycle,
      totalCycles: totalCycles ?? this.totalCycles,
      workDurationMinutes: workDurationMinutes ?? this.workDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;

  PomodoroNotifier()
      : super(PomodoroState(remainingSeconds: 25 * 60)) {
    _loadSettings();
  }

  void _loadSettings() {
    final box = HiveHelper.settings;
    final int work = box.get('pomodoroWork', defaultValue: 25);
    final int breakTime = box.get('pomodoroBreak', defaultValue: 5);
    final int cycles = box.get('pomodoroCycles', defaultValue: 2); // Default requirement says 2 sets

    state = state.copyWith(
      workDurationMinutes: work,
      breakDurationMinutes: breakTime,
      totalCycles: cycles,
      remainingSeconds: work * 60,
    );
  }

  Future<void> updateSettings({int? work, int? breakTime, int? cycles}) async {
    final box = HiveHelper.settings;
    if (work != null) await box.put('pomodoroWork', work);
    if (breakTime != null) await box.put('pomodoroBreak', breakTime);
    if (cycles != null) await box.put('pomodoroCycles', cycles);

    _loadSettings(); // Reload and reset
  }

  void startTimer() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _handlePhaseComplete();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resetTimer() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.workDurationMinutes * 60,
      phase: PomodoroPhase.work,
      currentCycle: 1,
    );
  }

  void _handlePhaseComplete() {
    _timer?.cancel();
    
    if (state.phase == PomodoroPhase.work) {
      // Work done, switch to break or finish if all cycles done
      // However, usually break comes after work.
      // Requirement: Work -> Break -> Work -> Break (until sets completed)
      
      if (state.currentCycle < state.totalCycles) {
        // Switch to break
        state = state.copyWith(
          phase: PomodoroPhase.breakTime,
          remainingSeconds: state.breakDurationMinutes * 60,
          isRunning: true,
        );
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
           if (state.remainingSeconds > 0) {
            state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
          } else {
            _handlePhaseComplete();
          }
        });
      } else {
        // Last work cycle done. Do we do a break? 
        // "Work -> Break -> Work -> Break" implies yes.
        // Let's assume after the last work, there is a last break or just finish.
        // "2 sets = 25 min work -> 5 min break -> repeat twice"
        // Cycle 1: Work (25) -> Break (5)
        // Cycle 2: Work (25) -> Break (5)
        // END.
        
        state = state.copyWith(
          phase: PomodoroPhase.breakTime,
          remainingSeconds: state.breakDurationMinutes * 60,
          isRunning: true,
        );
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
           if (state.remainingSeconds > 0) {
            state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
          } else {
            _handlePhaseComplete();
          }
        });
      }
    } else {
      // Break done.
      if (state.currentCycle < state.totalCycles) {
         // Next cycle starting
         state = state.copyWith(
           currentCycle: state.currentCycle + 1,
           phase: PomodoroPhase.work,
           remainingSeconds: state.workDurationMinutes * 60,
           isRunning: true,
         );
         _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
           if (state.remainingSeconds > 0) {
            state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
          } else {
            _handlePhaseComplete();
          }
        });
      } else {
        // All cycles done!
        resetTimer();
        // Ideally show a notification or sound
      }
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier();
});
