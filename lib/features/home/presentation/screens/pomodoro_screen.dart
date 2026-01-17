import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pomodoro/presentation/widgets/pomodoro_widget.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Pomodoro Timer"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: PomodoroWidget()),
      ),
    );
  }
}
