import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/consistency_provider.dart';

class DailyRatingWidget extends ConsumerWidget {
  const DailyRatingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(consistencyProvider);

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
              Row(
                children: [
                  Icon(Icons.nightlight_round, color: AppColors.primaryAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Daily Check-out",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Consistency Toggle (Glowing Pill)
              GestureDetector(
                onTap: () {
                  ref.read(consistencyProvider.notifier).toggleConsistency();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                    color: dailyLog.isConsistent ? AppColors.primaryAction.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20), 
                    border: Border.all(
                      color: dailyLog.isConsistent ? AppColors.primaryAction : AppColors.textSecondary.withOpacity(0.5),
                    ),
                    boxShadow: dailyLog.isConsistent ? [
                      BoxShadow(color: AppColors.primaryAction.withOpacity(0.3), blurRadius: 8)
                    ] : [],
                  ),
                  child: Row(
                    children: [
                      Text(
                        dailyLog.isConsistent ? "Complete" : "Mark Done",
                        style: TextStyle(
                          color: dailyLog.isConsistent ? AppColors.primaryAction : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      if (dailyLog.isConsistent) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check, color: AppColors.primaryAction, size: 14),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "How was your day?", 
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = starIndex <= dailyLog.rating;
              
              return GestureDetector(
                onTap: () {
                  ref.read(consistencyProvider.notifier).setRating(starIndex);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.amber.withOpacity(0.1) : Colors.transparent,
                  ),
                  child: AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 32,
                      color: isSelected ? Colors.amber[400] : AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (dailyLog.rating > 0) ...[
            const SizedBox(height: 16),
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: 1.0,
                child: Text(
                  dailyLog.rating == 5 ? "Amazing! 🌟 Saved" : 
                  dailyLog.rating == 4 ? "Great job! Saved" :
                  dailyLog.rating == 3 ? "Good day. Saved" : 
                  "Tomorrow is a new start. Saved",
                  style: TextStyle(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
