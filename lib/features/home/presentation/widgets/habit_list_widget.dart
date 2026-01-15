import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

class HabitListWidget extends ConsumerWidget {
  const HabitListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);

    if (habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.spa_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                "No habits yet.\nStart by adding one to build your flow.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: habits.map((habit) {
        final isDone = habit.isCompletedToday();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(habitProvider.notifier).toggleHabitCompletion(habit.id);
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).cardTheme.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text("Delete Habit", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    content: Text(
                      "Are you sure you want to delete '${habit.title}'?",
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(habitProvider.notifier).deleteHabit(habit.id);
                          Navigator.pop(context);
                        },
                        child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDone 
                      ? AppColors.primaryAction // Mint green when done
                      : Theme.of(context).cardTheme.color, // Dark/Glass when not
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDone 
                        ? AppColors.primaryAction 
                        : Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                  boxShadow: isDone 
                      ? [
                          BoxShadow(
                            color: AppColors.primaryAction.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ] 
                      : [],
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDone 
                            ? Colors.white.withOpacity(0.3) 
                            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
                        color: isDone 
                            ? AppColors.textPrimary // Dark icon on mint background
                            : Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Name and Streak info (optional)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDone 
                                  ? AppColors.textPrimary 
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.textPrimary.withOpacity(0.5),
                            ),
                          ),
                          if (habit.streak > 0 && !isDone)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "${habit.streak} day streak 🔥",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Checkbox/Status
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDone ? Colors.white : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isDone 
                            ? null 
                            : Border.all(color: AppColors.textSecondary.withOpacity(0.5), width: 2),
                      ),
                      child: isDone
                          ? Icon(Icons.check, color: AppColors.primaryAction, size: 20)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
