import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/consistency_graph_widget.dart';
import '../widgets/monthly_pie_chart_widget.dart';
import '../widgets/app_usage_list_widget.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Statistics",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryAccent,
              ),
            ),
            const SizedBox(height: 24),
            const ConsistencyGraphWidget(),
            const SizedBox(height: 16),
            const MonthlyPieChartWidget(),
            const SizedBox(height: 16),
            const AppUsageListWidget(),
          ],
        ),
      ),
    );
  }
}
