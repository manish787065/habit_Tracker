import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_usage/app_usage.dart';
import 'dart:io';

class AppUsageState {
  final List<AppUsageInfo> infos;
  final bool isLoading;
  final bool hasPermission;

  AppUsageState({
    required this.infos,
    this.isLoading = false, 
    this.hasPermission = false,
  });

  AppUsageState copyWith({List<AppUsageInfo>? infos, bool? isLoading, bool? hasPermission}) {
    return AppUsageState(
      infos: infos ?? this.infos,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class AppUsageNotifier extends StateNotifier<AppUsageState> {
  AppUsageNotifier() : super(AppUsageState(infos: [], isLoading: false));

  Future<void> fetchUsageStats() async {
    if (!Platform.isAndroid) return;

    state = state.copyWith(isLoading: true);
    
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(hours: 24));
      
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);
      
      // Filter out system apps if possible (logic is basic here)
      // Usually system apps have very short usage or specific package names
      // Sorting by usage
      infoList.sort((a, b) => b.usage.inSeconds.compareTo(a.usage.inSeconds));

      // Limit to top 5 for simplified view
      final topApps = infoList.where((i) => i.usage.inMinutes > 5).take(5).toList();

      state = state.copyWith(isLoading: false, infos: topApps, hasPermission: true);
    } catch (exception) {
      state = state.copyWith(isLoading: false, hasPermission: false);
    }
  }
}

final appUsageProvider = StateNotifierProvider<AppUsageNotifier, AppUsageState>((ref) {
  return AppUsageNotifier();
});
