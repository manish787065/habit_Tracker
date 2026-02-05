import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/navigation_provider.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(dashboardCategoryProvider);

    final List<Map<String, dynamic>> items = [
      {"label": "Home", "icon": Icons.home_outlined, "color": Colors.white},
      {"label": "Pomodoro", "icon": Icons.timer_outlined, "color": Colors.orange},
      {"label": "Habits", "icon": Icons.check_circle_outline, "color": Colors.green},
      {"label": "Study", "icon": Icons.menu_book_rounded, "color": Colors.blue},
      {"label": "Challenge", "icon": Icons.military_tech_outlined, "color": Colors.purple},
      {"label": "Tasks", "icon": Icons.task_alt_rounded, "color": Colors.teal},
      {"label": "Reflect", "icon": Icons.edit_note_rounded, "color": Colors.pink},
      {"label": "Settings", "icon": Icons.settings_outlined, "color": AppColors.primaryAction},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final defaultTextColor = isDark ? Colors.white : AppColors.textPrimary;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.45, // Slightly more than 40% for readability
      child: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            DrawerHeader(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.primaryAction.withOpacity(0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.auto_awesome, size: 30, color: AppColors.primaryAction),
                     const SizedBox(height: 8),
                     Text(
                      "Habit Tracker",
                      style: TextStyle(
                        color: defaultTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedCategory == item["label"];
                  
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      item["icon"], 
                      color: isSelected ? item["color"] : defaultIconColor,
                      size: 20,
                    ),
                    title: Text(
                      item["label"],
                      style: TextStyle(
                        color: isSelected ? item["color"] : defaultTextColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.primaryAction.withOpacity(0.1),
                    onTap: () {
                      ref.read(dashboardCategoryProvider.notifier).state = item["label"];
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
