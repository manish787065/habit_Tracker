import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/consistency_provider.dart';
import '../../../../core/data/hive_helper.dart';
import '../../../../core/logic/badge_logic.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

class DayCounterWidget extends ConsumerWidget {
  const DayCounterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider to rebuild on toggle
    final dailyLog = ref.watch(consistencyProvider);
    
    // Calculate Week: Sunday to Saturday
    final now = DateTime.now();
    // Find last Sunday (or today if Sunday)
    final lastSunday = now.subtract(Duration(days: now.weekday % 7));
    
    final weekDays = List.generate(7, (index) {
      return lastSunday.add(Duration(days: index));
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Icon(Icons.bolt_rounded, color: AppColors.primaryAction, size: 20),
                       const SizedBox(width: 8),
                       Text(
                         "Consistency",
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                           color: Theme.of(context).textTheme.bodyLarge?.color,
                           letterSpacing: -0.5,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 4),
                   Text(
                     "Keep the streak alive!",
                     style: TextStyle(
                       fontSize: 13,
                       color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                     ),
                   ),
                 ],
               ),
                IconButton(
                  icon: Icon(Icons.calendar_month_rounded, color: AppColors.textSecondary, size: 24),
                  onPressed: () => _pickDate(context, ref),
                ),
              ],
            ),
           const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays.map((date) {
              final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
              final dateStr = date.toIso8601String().split('T')[0];
              
              bool isConsistent = false;
              if (isToday) {
                isConsistent = dailyLog.isConsistent;
              } else {
                isConsistent = HiveHelper.habits.get('consistency_$dateStr', defaultValue: false);
              }

              // Color Logic
              Color boxColor;
              Color textColor;
              
              if (isConsistent) {
                boxColor = AppColors.primaryAction;
                textColor = AppColors.textPrimary;
              } else if (isToday) {
                boxColor = AppColors.primaryAction.withOpacity(0.1);
                textColor = AppColors.primaryAction;
              } else {
                boxColor = Colors.transparent;
                textColor = AppColors.textSecondary;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: isToday ? () {
                          ref.read(consistencyProvider.notifier).toggleConsistency();
                        } : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 50, // Slightly reduced height to prevent vertical overflow issues if any
                          constraints: const BoxConstraints(minWidth: 32),
                          decoration: BoxDecoration(
                            color: boxColor,
                            borderRadius: BorderRadius.circular(16), // Slightly smaller radius for narrower pills
                            border: (isToday && !isConsistent) 
                                ? Border.all(color: AppColors.primaryAction.withOpacity(0.5), width: 1.5) 
                                : null,
                            boxShadow: isConsistent 
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryAction.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ] 
                                : [],
                          ),
                          child: Center(
                            child: isConsistent 
                                ? const Icon(Icons.check, size: 18, color: AppColors.textPrimary)
                                : Text(
                                    "${date.day}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('E').format(date)[0],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isToday ? AppColors.primaryAction : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            ),
          ],
        ),
      );
    }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryAction, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Theme.of(context).textTheme.bodyLarge?.color, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryAction, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _showHistoryDialog(context, picked, ref);
    }
  }

  void _showHistoryDialog(BuildContext context, DateTime date, WidgetRef ref) {
    final dateStr = date.toIso8601String().split('T')[0];
    final box = HiveHelper.habits;

    // Fetch Data
    final double studyHours = box.get('study_hours_$dateStr', defaultValue: 0.0) / 3600;
    final bool isConsistent = box.get('consistency_$dateStr', defaultValue: false);
    final int rating = box.get('rating_$dateStr', defaultValue: 0);
    final BadgeType badge = BadgeLogic.getBadgeForHours(studyHours);
    final BadgeInfo badgeInfo = BadgeLogic.getInfo(badge);

    // Completed Habits
    // Ideally we should use the provider if loaded, or fetch from Hive manually if we want to be pure.
    // Provider is safer.
    final habits = ref.read(habitProvider);
    final completedHabits = habits.where((h) => 
      h.completedDays.any((d) => 
        d.year == date.year && d.month == date.month && d.day == date.day
      )
    ).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM d, y').format(date),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              _buildHistoryRow(context, Icons.timer, "Study Hours", "${studyHours.toStringAsFixed(1)} hrs"),
              _buildHistoryRow(context, Icons.check_circle_outline, "Daily Goal", isConsistent ? "Completed" : "Missed"),
              _buildHistoryRow(context, Icons.star_border, "Rating", rating > 0 ? "$rating/5" : "Not rated"),
              if (badge != BadgeType.none)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                       Icon(badgeInfo.icon, color: badgeInfo.color),
                       const SizedBox(width: 12),
                       Text("Earned: ${badgeInfo.name}", style: TextStyle(color: badgeInfo.color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              Text("Habits Completed:", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 8),
              if (completedHabits.isEmpty)
                 Text("No habits completed.", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)))
              else
                Wrap(
                  spacing: 8,
                  children: completedHabits.map((h) => Chip(
                    label: Text(h.title, style: const TextStyle(fontSize: 10)),
                    backgroundColor: AppColors.secondaryAccent.withOpacity(0.2),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }
}
