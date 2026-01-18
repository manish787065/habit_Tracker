import 'dart:async';
import 'package:flutter/material.dart'; // For Color
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/hive_helper.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/study_subject.dart';

class StudyState {
  final double totalSeconds; // Total for today across all subjects
  final bool isTimerRunning;
  final List<StudySubject> subjects;
  final String? selectedSubjectId;

  StudyState({
    required this.totalSeconds,
    required this.isTimerRunning,
    this.subjects = const [],
    this.selectedSubjectId,
  });

  double get totalHours => totalSeconds / 3600;
  
  StudySubject? get selectedSubject {
    if (selectedSubjectId == null) return null;
    try {
      return subjects.firstWhere((s) => s.id == selectedSubjectId);
    } catch (_) {
      return null;
    }
  }

  StudyState copyWith({
    double? totalSeconds,
    bool? isTimerRunning,
    List<StudySubject>? subjects,
    String? selectedSubjectId,
  }) {
    return StudyState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      subjects: subjects ?? this.subjects,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId, // Allow nulling? If passed null, it stays same? No, typical copyWith logic.
      // Actually, to set to null, we'd need a sentinel. For simplicity, we assume we don't unset it often or handle it if needed.
      // But wait, if I want to switch subject I just pass new ID.
    );
  }
  
  // Custom copyWith to allow nullable selectedSubjectId update
  StudyState copyWithSelect({
    String? selectedSubjectId, // Nullable to deselect
    double? totalSeconds,
    bool? isTimerRunning,
    List<StudySubject>? subjects,
  }) {
     return StudyState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      subjects: subjects ?? this.subjects,
      selectedSubjectId: selectedSubjectId, // Explicitly set
    );
  }
}

class StudyHoursNotifier extends StateNotifier<StudyState> {
  Timer? _timer;
  final Ref ref;

  StudyHoursNotifier(this.ref) : super(StudyState(totalSeconds: 0, isTimerRunning: false)) {
    _loadData();
  }

  void _loadData() {
    final box = HiveHelper.habits;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // 1. Total Seconds for Today
    final double savedSeconds = box.get('study_hours_$today', defaultValue: 0.0);
    
    // 2. Load Subjects
    final List<dynamic> subjectsRaw = box.get('study_subjects', defaultValue: []);
    List<StudySubject> loadedSubjects = subjectsRaw
        .map((e) => StudySubject.fromMap(Map<String, dynamic>.from(e)))
        .toList();
        
    // 3. Check Date Reset for Subjects
    final String lastDate = box.get('study_last_date', defaultValue: '');
    if (lastDate != today) {
      // Reset todaySeconds for all subjects
      loadedSubjects = loadedSubjects.map((s) => s.copyWith(todaySeconds: 0)).toList();
      box.put('study_last_date', today);
      _saveSubjectsList(loadedSubjects);
    }
    
    state = StudyState(
      totalSeconds: savedSeconds, 
      isTimerRunning: false,
      subjects: loadedSubjects,
    );
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
  
  Future<void> _saveSubjectsList(List<StudySubject> subjects) async {
    final box = HiveHelper.habits;
    final subjectsMap = subjects.map((e) => e.toMap()).toList();
    await box.put('study_subjects', subjectsMap);
  }

  Future<void> addSubject(String name, int colorValue, double dailyTargetHours) async {
    final newSubject = StudySubject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      colorValue: colorValue,
      dailyTargetSeconds: dailyTargetHours * 3600,
    );
    
    final newSubjects = [...state.subjects, newSubject];
    state = state.copyWith(subjects: newSubjects, selectedSubjectId: newSubject.id);
    await _saveSubjectsList(newSubjects);
  }
  
  void selectSubject(String? id) {
    if (state.isTimerRunning) return; // Don't switch while running
    // Use copyWithSelect-like logic manually
    state = StudyState(
      totalSeconds: state.totalSeconds,
      isTimerRunning: state.isTimerRunning,
      subjects: state.subjects,
      selectedSubjectId: id,
    );
  }

  void startTimer() {
    if (state.isTimerRunning) return; 
    
    // Require a subject if subjects exist? User requirement implies subject-wise study.
    // If no subject selected, maybe just global timer? 
    // Let's enforce subject selection if possible, or create a default "General".
    // For now, if no subject selected, it just adds to total.
    
    state = state.copyWith(isTimerRunning: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newSeconds = state.totalSeconds + 1;
      
      // Update Subject if selected
      List<StudySubject> currentSubjects = state.subjects;
      if (state.selectedSubjectId != null) {
        currentSubjects = state.subjects.map((s) {
          if (s.id == state.selectedSubjectId) {
             return s.copyWith(
               totalSeconds: s.totalSeconds + 1,
               todaySeconds: s.todaySeconds + 1,
             );
          }
          return s;
        }).toList();
        
        // Save subjects periodically (every 10s is too frequent for hive potentially? 
        // hive is fast. Let's do it.)
        if (newSeconds % 10 == 0) {
           _saveSubjectsList(currentSubjects);
        }
      }

      // Award 10 points for every full hour (3600s)
      if (newSeconds % 3600 == 0) {
        // Daily points cap? Or unlimited?
        ref.read(authProvider.notifier).addPoints(10);
      }
      
      state = state.copyWith(totalSeconds: newSeconds, subjects: currentSubjects);
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
    if (state.subjects.isNotEmpty) {
      _saveSubjectsList(state.subjects);
    }
  }

  void addManualHours(double hours) {
    final secondsToAdd = hours * 3600;
    if (secondsToAdd + state.totalSeconds < 0) return;
    
    // Add to selected subject if any
    List<StudySubject> currentSubjects = state.subjects;
    if (state.selectedSubjectId != null) {
       currentSubjects = state.subjects.map((s) {
          if (s.id == state.selectedSubjectId) {
             return s.copyWith(
               totalSeconds: s.totalSeconds + secondsToAdd,
               todaySeconds: s.todaySeconds + secondsToAdd,
             );
          }
          return s;
       }).toList();
       _saveSubjectsList(currentSubjects);
    }
    
    state = state.copyWith(
      totalSeconds: state.totalSeconds + secondsToAdd,
      subjects: currentSubjects
    );
    _saveHours();
  }

  List<Map<String, dynamic>> getHistory() {
    final box = HiveHelper.habits;
    final List<String> daysIndex = List<String>.from(box.get('study_days_index', defaultValue: []));
    
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
