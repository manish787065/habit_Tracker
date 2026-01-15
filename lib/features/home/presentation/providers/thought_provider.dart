import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/hive_helper.dart';

class ThoughtNotifier extends StateNotifier<String> {
  ThoughtNotifier() : super("") {
    _loadThought();
  }

  void _loadThought() {
    final box = HiveHelper.habits; // Reusing habits box or settings
    final today = DateTime.now().toIso8601String().split('T')[0];
    final thought = box.get('thought_$today', defaultValue: "") as String;
    state = thought;
  }

  Future<void> saveThought(String text) async {
    final box = HiveHelper.habits;
    final today = DateTime.now().toIso8601String().split('T')[0];
    await box.put('thought_$today', text);
    state = text;
  }
}

final thoughtProvider = StateNotifierProvider<ThoughtNotifier, String>((ref) {
  return ThoughtNotifier();
});
