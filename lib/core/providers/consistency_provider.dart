import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/hive_helper.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class DailyLog {
  final bool isConsistent;
  final int rating;

  DailyLog({required this.isConsistent, required this.rating});

  DailyLog copyWith({bool? isConsistent, int? rating}) {
    return DailyLog(
      isConsistent: isConsistent ?? this.isConsistent,
      rating: rating ?? this.rating,
    );
  }
}

class ConsistencyNotifier extends StateNotifier<DailyLog> {
  final Ref ref;

  ConsistencyNotifier(this.ref) : super(DailyLog(isConsistent: false, rating: 0)) {
    _loadTodayLog();
  }

  void _loadTodayLog() {
    final box = HiveHelper.habits; // Reusing habits box
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final bool consistent = box.get('consistency_$today', defaultValue: false);
    final int rating = box.get('rating_$today', defaultValue: 0);
    
    state = DailyLog(isConsistent: consistent, rating: rating);
  }

  Future<void> toggleConsistency() async {
    final box = HiveHelper.habits;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final newValue = !state.isConsistent;
    
    // Save to Hive
    await box.put('consistency_$today', newValue);
    
    // Update local state
    state = state.copyWith(isConsistent: newValue);
    
    // Update Points
    if (newValue) {
       ref.read(authProvider.notifier).addPoints(5);
    } else {
       ref.read(authProvider.notifier).deductPoints(5);
    }
  }

  Future<void> setRating(int value) async {
    final box = HiveHelper.habits;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await box.put('rating_$today', value);
    state = state.copyWith(rating: value);
  }
}

final consistencyProvider = StateNotifierProvider<ConsistencyNotifier, DailyLog>((ref) {
  return ConsistencyNotifier(ref);
});
