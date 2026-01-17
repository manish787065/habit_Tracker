import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/hive_helper.dart';

class YearlyConsistencyGraph extends StatelessWidget {
  const YearlyConsistencyGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<List<DateTime>> weeks = [];
    final startDate = now.subtract(const Duration(days: 364));
    final int daysSinceMonday = startDate.weekday - 1; 
    final alignedStartDate = startDate.subtract(Duration(days: daysSinceMonday));
    List<DateTime> currentWeek = [];
    DateTime iterator = alignedStartDate;
    final totalDays = 53 * 7;
    for (int i = 0; i < totalDays; i++) {
      currentWeek.add(iterator);
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
      iterator = iterator.add(const Duration(days: 1));
      if (iterator.isAfter(now) && currentWeek.isEmpty) break; 
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Progress",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 32),
                    ...List.generate(weeks.length, (index) {
                      final weekStart = weeks[index].first;
                      bool showLabel = false;
                      if (index == 0) {
                        showLabel = true;
                      } else {
                        final prevWeekStart = weeks[index - 1].first;
                        if (prevWeekStart.month != weekStart.month) {
                          showLabel = true;
                        }
                      }
                      return Container(
                        width: 15, // Match column width exactly (12 + 3 padding)
                        alignment: Alignment.centerLeft,
                        child: showLabel 
                            ? Text(
                                DateFormat('MMM').format(weekStart),
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold
                                ),
                                overflow: TextOverflow.visible,
                                softWrap: false,
                              )
                            : null,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 0),
                          Text("Mon", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          const SizedBox(height: 14),
                          Text("Wed", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          const SizedBox(height: 14),
                          Text("Fri", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: weeks.map((week) {
                         return Padding(
                           padding: const EdgeInsets.only(right: 3),
                           child: Column(
                             children: week.map((date) {
                           if (date.isAfter(now)) {
                             return Container(
                               width: 12, 
                               height: 12, 
                               margin: const EdgeInsets.only(bottom: 3),
                             );
                           }
                           final dateStr = date.toIso8601String().split('T')[0];
                           final bool isConsistent = HiveHelper.habits.get('consistency_$dateStr', defaultValue: false);
                           // Intensity Logic
                           // Level 0: No Consistency
                           // Level 1: Consistent
                           // Level 2: Consistent + >1hr study (3600s)
                           // Level 3: Consistent + >3hrs study (10800s)
                           
                           final double studySeconds = HiveHelper.habits.get('study_hours_$dateStr', defaultValue: 0.0);
                           
                           Color color = isConsistent 
                               ? AppColors.primaryAction 
                               : AppColors.secondaryAccent.withOpacity(0.05); // Base faint color for empty
                           
                           if (isConsistent) {
                             if (studySeconds > 10800) {
                               color = AppColors.primaryAction; // Solid
                             } else if (studySeconds > 3600) {
                               color = AppColors.primaryAction.withOpacity(0.7);
                             } else {
                               color = AppColors.primaryAction.withOpacity(0.4);
                             }
                           } else if (studySeconds > 0) {
                             // Not consistent but studied
                              color = AppColors.primaryAction.withOpacity(0.2);
                           }
                           return Tooltip(
                             message: "$dateStr\n${isConsistent ? 'Consistent' : 'Not Consistent'}\n${(studySeconds/3600).toStringAsFixed(1)} hrs study",
                             child: Container(
                               width: 12,
                               height: 12,
                               margin: const EdgeInsets.only(bottom: 3),
                               decoration: BoxDecoration(
                                 color: color,
                                 borderRadius: BorderRadius.circular(2),
                               ),
                             ),
                           );
                         }).toList(),
                       ),
                     );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Less", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(width: 4),
          Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.secondaryAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 2),
          Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.primaryAction, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text("More", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      )
    ],
  ),
);
  }
}
