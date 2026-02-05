import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/pomodoro_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class PomodoroFocusScreen extends ConsumerStatefulWidget {
  const PomodoroFocusScreen({super.key});

  @override
  ConsumerState<PomodoroFocusScreen> createState() => _PomodoroFocusScreenState();
}

class _PomodoroFocusScreenState extends ConsumerState<PomodoroFocusScreen> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    // Play sound immediately to confirm start
    _playSound();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (ref.read(pomodoroProvider).isRunning) {
         ref.read(pomodoroProvider.notifier).pauseTimer();
      }
    }
  }

// ... _formatTime and _playSound and _handleBack and _quit (same as before)

  String _formatTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _playSound() async {
    // Tactile feedback
    HapticFeedback.heavyImpact();
    
    try {
      await _audioPlayer.play(AssetSource('sounds/bell.mp3'));
    } catch (e) {
      debugPrint("Asset sound failed, trying network backup: $e");
      try {
        // Fallback to a generic beep if local asset missing
        await _audioPlayer.play(UrlSource('https://codeskulptor-demos.commondatastorage.googleapis.com/GalaxyInvaders/pause.mp3'));
      } catch (e2) {
         debugPrint("Network sound failed: $e2");
      }
    }
  }

  void _handleBack() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Stop Timer?"),
        content: const Text(
            "If you leave now, the timer will reset and you will lose 10 points. Stay focused!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Resume"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _quit();
            },
            child: const Text("Give Up", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _quit() {
    ref.read(pomodoroProvider.notifier).resetTimer();
    ref.read(authProvider.notifier).deductPoints(10);
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroProvider);

    ref.listen(pomodoroProvider, (prev, next) {
      if (prev?.phase != next.phase) {
        _playSound();
      }
    });

    Color statusColor = state.phase == PomodoroPhase.work 
        ? AppColors.primaryAction 
        : Colors.green;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: _handleBack,
                    ),
                    const Spacer(),
                    const Text(
                      "Deep Focus",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),

              const Spacer(),

              // Timer
              // Timer
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 8),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.phase == PomodoroPhase.work 
                            ? Icons.self_improvement 
                            : Icons.coffee,
                        color: statusColor,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _formatTime(state.remainingSeconds),
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                         state.isRunning 
                           ? (state.phase == PomodoroPhase.work ? "Focus Time" : "Break Time")
                           : "Paused",
                         style: const TextStyle(color: Colors.white70, fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                "Cycle ${state.currentCycle} / ${state.totalCycles}",
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),

              const Spacer(),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: const Text(
                  "Keep existing... You are doing great!",
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
