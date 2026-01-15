import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/pomodoro_provider.dart';
import 'dart:ui';

class PomodoroWidget extends ConsumerWidget {
  const PomodoroWidget({super.key});

  String _formatTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showCustomizeDialog(BuildContext context, WidgetRef ref, PomodoroState state) {
    final workController = TextEditingController(text: state.workDurationMinutes.toString());
    final breakController = TextEditingController(text: state.breakDurationMinutes.toString());
    final cyclesController = TextEditingController(text: state.totalCycles.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Customize Timer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: workController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Work Duration (min)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: breakController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Break Duration (min)"),
            ),
             const SizedBox(height: 10),
            TextField(
              controller: cyclesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Total Cycles (sets)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final work = int.tryParse(workController.text);
              final breakTime = int.tryParse(breakController.text);
              final cycles = int.tryParse(cyclesController.text);
              
              if (work != null && breakTime != null && cycles != null) {
                ref.read(pomodoroProvider.notifier).updateSettings(
                  work: work, 
                  breakTime: breakTime,
                  cycles: cycles,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);

    Color statusColor = state.phase == PomodoroPhase.work ? AppColors.primaryAction : Colors.green;
    String statusText = state.phase == PomodoroPhase.work ? "Focus Time" : "Break Time";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pomodoro Timer",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showCustomizeDialog(context, ref, state),
                tooltip: "Customize",
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Timer Display
              Column(
                children: [
                  Text(
                    _formatTime(state.remainingSeconds),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    "$statusText • Cycle ${state.currentCycle}/${state.totalCycles}",
                    style: TextStyle(
                      fontSize: 14, 
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                    ),
                  ),
                ],
              ),
              // Controls
              GestureDetector(
                onTap: () {
                  if (state.isRunning) {
                     ref.read(pomodoroProvider.notifier).pauseTimer();
                  } else {
                     ref.read(pomodoroProvider.notifier).startTimer();
                  }
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                       BoxShadow(
                        color: statusColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                       )
                    ],
                  ),
                  child: Icon(
                    state.isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          if (!state.isRunning && state.remainingSeconds != state.workDurationMinutes * 60)
             Padding(
               padding: const EdgeInsets.only(top: 10),
               child: TextButton(
                 onPressed: () => ref.read(pomodoroProvider.notifier).resetTimer(),
                 child: const Text("Reset"),
               ),
             )
        ],
      ),
    );
  }
}
