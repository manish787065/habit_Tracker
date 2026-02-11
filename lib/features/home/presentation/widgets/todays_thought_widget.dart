import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/thought_provider.dart';

class TodaysThoughtWidget extends ConsumerStatefulWidget {
  const TodaysThoughtWidget({super.key});

  @override
  ConsumerState<TodaysThoughtWidget> createState() => _TodaysThoughtWidgetState();
}

class _TodaysThoughtWidgetState extends ConsumerState<TodaysThoughtWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thought = ref.watch(thoughtProvider);
    
    if (_controller.text.isEmpty && thought.isNotEmpty) {
      _controller.text = thought;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }

    return Container(
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
            children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: AppColors.secondaryAccent.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.auto_awesome_rounded, color: AppColors.secondaryAccent, size: 20),
               ),
              const SizedBox(width: 12),
               Text(
                "Life Lesson",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.02)),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 3,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.5,
              ),
              onChanged: (val) {
                ref.read(thoughtProvider.notifier).saveThought(val);
              },
              decoration: InputDecoration(
                hintText: "What's on your mind today?",
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
