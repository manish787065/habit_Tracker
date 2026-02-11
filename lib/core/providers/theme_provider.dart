import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/hive_helper.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() {
    final box = HiveHelper.settings;
    final savedTheme = box.get('themeMode');
    if (savedTheme == 'dark') {
      state = ThemeMode.dark;
    } else if (savedTheme == 'system') {
      state = ThemeMode.system;
    } else {
      // Default to Light even if 'light' is saved or if nothing is saved
      state = ThemeMode.light;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final box = HiveHelper.settings;
    String themeString = 'system';
    if (mode == ThemeMode.light) themeString = 'light';
    if (mode == ThemeMode.dark) themeString = 'dark';
    await box.put('themeMode', themeString);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
