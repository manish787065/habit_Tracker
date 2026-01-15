import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../providers/study_hours_provider.dart';

class StudyHoursWidget extends ConsumerStatefulWidget {
  const StudyHoursWidget({super.key});

  @override
  ConsumerState<StudyHoursWidget> createState() => _StudyHoursWidgetState();
}

class _StudyHoursWidgetState extends ConsumerState<StudyHoursWidget> {
  final TextEditingController _manualController = TextEditingController();

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
         title: Text("Enter Study Hours", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: TextField(
          controller: _manualController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
           style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: "Hours (e.g. 1.5)",
            labelStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textSecondary)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.secondaryAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryAccent),
            onPressed: () {
              final val = double.tryParse(_manualController.text);
              if (val != null) {
                ref.read(studyHoursProvider.notifier).addManualHours(val);
                _manualController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyState = ref.watch(studyHoursProvider);
    final isRunning = studyState.isTimerRunning;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 children: [
                   Icon(Icons.timer_outlined, color: AppColors.secondaryAccent, size: 20),
                   const SizedBox(width: 8),
                   Text(
                     "Study Timer",
                     style: TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                       color: Theme.of(context).textTheme.bodyLarge?.color,
                       letterSpacing: -0.5,
                     ),
                   ),
                 ],
               ),
              IconButton(
                onPressed: _showManualEntryDialog,
                icon: Icon(Icons.add_rounded, color: AppColors.textSecondary),
                tooltip: "Manual Entry",
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    _formatTime(studyState.totalSeconds.toInt()),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: isRunning ? AppColors.secondaryAccent : Theme.of(context).textTheme.bodyLarge?.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: -2,
                    ),
                  ),
                   Text(
                    isRunning ? "Focusing..." : "Total Time Today",
                    style: TextStyle(
                      fontSize: 14,
                      color: isRunning ? AppColors.secondaryAccent : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Timer Control
              GestureDetector(
                onTap: () {
                  if (studyState.isTimerRunning) {
                    ref.read(studyHoursProvider.notifier).stopTimer();
                  } else {
                    ref.read(studyHoursProvider.notifier).startTimer();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: studyState.isTimerRunning ? Colors.redAccent.withOpacity(0.1) : AppColors.secondaryAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (studyState.isTimerRunning ? Colors.redAccent : AppColors.secondaryAccent).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: studyState.isTimerRunning ? Border.all(color: Colors.redAccent, width: 2) : null,
                  ),
                  child: Icon(
                    studyState.isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: studyState.isTimerRunning ? Colors.redAccent : Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
