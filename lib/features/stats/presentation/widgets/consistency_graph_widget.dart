import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    final double maxVal = weeklyData.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal + 1).ceilToDouble();

    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
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
                  Text(
                    "Study Consistency",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Last 7 Days Progress",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Icon(Icons.auto_graph_rounded, color: AppColors.primaryAccent),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < 7) {
                          final date = DateTime.now().subtract(Duration(days: 6 - index));
                          final dateStr = DateFormat('dd MMM').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              dateStr,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}h",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY < 6 ? 6 : maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primaryAccent,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primaryAccent,
                          strokeWidth: 2,
                          strokeColor: AppColors.cardBackground,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryAccent.withOpacity(0.2),
                          AppColors.primaryAccent.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.cardBackground,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = DateTime.now().subtract(Duration(days: 6 - spot.x.toInt()));
                        final dateStr = DateFormat('dd MMM').format(date);
                        return LineTooltipItem(
                          "$dateStr\n",
                          const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          children: [
                            TextSpan(
                              text: "${spot.y.toStringAsFixed(1)} hrs",
                              style: const TextStyle(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
}
