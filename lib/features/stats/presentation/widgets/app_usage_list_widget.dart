import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/app_usage_provider.dart';

class AppUsageListWidget extends ConsumerWidget {
  const AppUsageListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUsageProvider);
    final notifier = ref.read(appUsageProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Digital Wellbeing",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              if (state.hasPermission)
                IconButton(
                  icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
                  onPressed: () => notifier.fetchUsageStats(),
                )
            ],
          ),
          const SizedBox(height: 20),
          
          if (state.isLoading)
             const Center(child: CircularProgressIndicator())
          else if (!state.hasPermission)
            Center(
              child: Column(
                children: [
                  Icon(Icons.lock_clock, size: 48, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 12),
                  Text(
                    "Connect to view usage stats",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => notifier.fetchUsageStats(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Grant Permission", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            )
          else if (state.infos.isEmpty)
             Center(child: Text("No significant usage found today.", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.infos.length,
              itemBuilder: (context, index) {
                final info = state.infos[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.android, size: 20, color: Theme.of(context).colorScheme.primary), // Placeholder icon
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.packageName.split('.').last.toUpperCase(), // Simple name extraction
                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            const SizedBox(height: 4),
                             LinearProgressIndicator(
                                value: info.usage.inMinutes / 120, // Arbitrary max 2 hours for bar scaling
                                backgroundColor: Theme.of(context).dividerColor,
                                valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                                borderRadius: BorderRadius.circular(4),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${info.usage.inHours}h ${info.usage.inMinutes % 60}m",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                );
              },
            )
        ],
      ),
    );
  }
}
