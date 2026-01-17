import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/hive_helper.dart';
import '../../domain/gamification_types.dart';

class GamificationNotifier extends StateNotifier<GamificationTheme> {
  GamificationNotifier() : super(GamificationTheme.litti) {
    _loadTheme();
  }

  void _loadTheme() {
    final box = HiveHelper.habits; // Reusing habits box for general user pref if ok, or create new? 
    // HiveHelper might need update if we want a dedicated box, but habits box is likely fine for preferences for now.
    // Actually, let's check HiveHelper usage. defaulting to habits box.
    
    final String? themeName = box.get('gamification_theme');
    if (themeName != null) {
      try {
        state = GamificationTheme.values.firstWhere((e) => e.name == themeName);
      } catch (_) {
        state = GamificationTheme.litti;
      }
    }
  }

  Future<void> setTheme(GamificationTheme theme) async {
    final box = HiveHelper.habits;
    await box.put('gamification_theme', theme.name);
    state = theme;
  }
}

final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationTheme>((ref) {
  return GamificationNotifier();
});
