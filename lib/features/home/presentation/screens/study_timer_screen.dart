import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/study_hours_widget.dart';

class StudyTimerScreen extends StatelessWidget {
  const StudyTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Study Timer"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: StudyHoursWidget()),
      ),
    );
  }
}
