import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../habits/presentation/providers/habit_provider.dart';

class MonthlyPieChartWidget extends ConsumerWidget {
  const MonthlyPieChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);
    
    // Calculate Monthly Completion Rate
    int totalCompletionsThisMonth = 0;
    int totalOpportunities = 0;
    
    final now = DateTime.now();
    final daysInMonthSoFar = now.day;
    
    for (var habit in habits) {
      // Opportunities: Simple assumption - habit existed all month. 
      // Ideally we'd check creation date but for now this is "Success rate based on active habits"
      totalOpportunities += daysInMonthSoFar;

      totalCompletionsThisMonth += habit.completedDays.where((date) => 
        date.year == now.year && date.month == now.month
      ).length;
    }

    double successRate = 0;
    if (habits.isNotEmpty && totalOpportunities > 0) {
      successRate = (totalCompletionsThisMonth / totalOpportunities) * 100;
      if (successRate > 100) successRate = 100; // Just in case
    } else if (habits.isEmpty) {
        // Special case for no habits
        successRate = 0;
    }

    final missedRate = 100 - successRate;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Habit Success",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: habits.isEmpty 
            ? Center(child: Text("No habits to track yet", style: TextStyle(color: AppColors.textSecondary)))
            : Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.primaryAction, // Completed
                        value: successRate,
                        title: '',
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: AppColors.secondaryAccent.withOpacity(0.3), // Missed
                        value: missedRate,
                        title: '',
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${successRate.toInt()}%",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        "Success",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
