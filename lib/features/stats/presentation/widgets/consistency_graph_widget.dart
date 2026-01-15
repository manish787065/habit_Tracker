import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/study_hours_provider.dart';

class ConsistencyGraphWidget extends ConsumerWidget {
  const ConsistencyGraphWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state to trigger rebuilds on timer tick
    ref.watch(studyHoursProvider);
    final weeklyData = ref.read(studyHoursProvider.notifier).getWeeklyData();
    
    // Calculate maxY for dynamic scaling (+1 hour buffer)
    final maxY = (weeklyData.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Study Consistency",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Last 7 Days (Hours)",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Icon(Icons.show_chart, color: AppColors.primaryAccent),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < 7) {
                          // Calculate day label dynamically (e.g., M, T, W)
                          final date = DateTime.now().subtract(Duration(days: 6 - index));
                          final dayName = _getDayName(date.weekday);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayName,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY < 5 ? 5 : maxY, // Minimum 5 hours scale
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primaryAccent,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                         return FlDotCirclePainter(
                           radius: 4,
                           color: AppColors.primaryAccent,
                           strokeWidth: 2,
                           strokeColor: Colors.white,
                         );
                    }),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryAccent.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                   tooltipBgColor: AppColors.cardBackground, 
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "${spot.y.toStringAsFixed(1)} hrs",
                          const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[weekday - 1];
  }
}
