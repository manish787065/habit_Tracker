import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/gamification_provider.dart';
import '../../domain/gamification_types.dart';

class PointListenerWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const PointListenerWrapper({super.key, required this.child});

  @override
  ConsumerState<PointListenerWrapper> createState() => _PointListenerWrapperState();
}

class _PointListenerWrapperState extends ConsumerState<PointListenerWrapper> {
  int? _previousPoints;

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(authProvider, (previous, next) {
      if (previous != null && next != null) {
        final diff = next.points - previous.points;
        if (diff > 0) {
          _showReward(diff);
        }
      }
    });

    return widget.child;
  }

  void _showReward(int amount) {
    final theme = ref.read(gamificationProvider);
    final themeName = theme.displayName; // "Litti", "Momo"
    final themeEmoji = theme.emoji;

    // Use a plural logic if simple
    final String label = amount == 1 ? themeName : '${themeName}s';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(themeEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "You earned $amount $label!",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
