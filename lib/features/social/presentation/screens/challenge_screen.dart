import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/study_hours_provider.dart';

class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studyState = ref.watch(studyHoursProvider);
    final myHours = studyState.totalHours;

    // Mock Friends Data
    final List<Map<String, dynamic>> friends = [
      {'name': 'Alex', 'hours': 3.5},
      {'name': 'Sarah', 'hours': 5.2},
      {'name': 'Mike', 'hours': 1.8},
      {'name': 'Emma', 'hours': 4.0},
    ];

    // Add current user to list
    final List<Map<String, dynamic>> leaderboard = [
      ...friends,
      {'name': 'You', 'hours': myHours, 'isMe': true},
    ];

    // Sort by hours descending
    leaderboard.sort((a, b) => (b['hours'] as double).compareTo(a['hours'] as double));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryAction, AppColors.primaryAction.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAction.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Weekly Challenge",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Keep pushing! You are doing great.",
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Friends Leaderboard",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = leaderboard[index];
                  final isMe = entry['isMe'] == true;
                  final double hours = entry['hours'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primaryAction.withOpacity(0.1) : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? Border.all(color: AppColors.primaryAction) : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "#${index + 1}",
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          backgroundColor: isMe ? AppColors.primaryAction : AppColors.secondaryAccent,
                          child: Text(
                             (entry['name'] as String)[0],
                             style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          "${hours.toStringAsFixed(1)} hrs",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
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
