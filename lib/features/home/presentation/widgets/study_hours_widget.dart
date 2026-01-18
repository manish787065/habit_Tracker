import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../providers/study_hours_provider.dart';
// import domain if needed for color access, or use dynamic
import '../../domain/study_subject.dart';

class StudyHoursWidget extends ConsumerStatefulWidget {
  const StudyHoursWidget({super.key});

  @override
  ConsumerState<StudyHoursWidget> createState() => _StudyHoursWidgetState();
}

class _StudyHoursWidgetState extends ConsumerState<StudyHoursWidget> {
  final TextEditingController _manualController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void dispose() {
    _manualController.dispose();
    _subjectNameController.dispose();
    _targetController.dispose();
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

  void _showAddSubjectDialog() {
    _selectedColor = Colors.blue; // Reset
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Text("Add Subject", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _subjectNameController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(labelText: "Subject Name", labelStyle: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                     style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(labelText: "Daily Target (Hours)", labelStyle: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  const Text("Color", style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink
                    ].map((color) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => _selectedColor = color),
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 12,
                          child: _selectedColor == color ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryAccent),
                onPressed: () {
                  if (_subjectNameController.text.isNotEmpty) {
                    final target = double.tryParse(_targetController.text) ?? 1.0;
                    ref.read(studyHoursProvider.notifier).addSubject(
                      _subjectNameController.text,
                      _selectedColor.value,
                      target,
                    );
                    _subjectNameController.clear();
                    _targetController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Create"),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studyState = ref.watch(studyHoursProvider);
    final isRunning = studyState.isTimerRunning;
    final selectedSubject = studyState.selectedSubject;
    final subjects = studyState.subjects;

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
               Expanded(
                 child: Row(
                   children: [
                     Icon(Icons.timer_outlined, color: AppColors.secondaryAccent, size: 20),
                     const SizedBox(width: 8),
                     Text(
                       selectedSubject != null ? selectedSubject.name : "Study Timer",
                       style: TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: selectedSubject != null ? Color(selectedSubject.colorValue) : Theme.of(context).textTheme.bodyLarge?.color,
                         letterSpacing: -0.5,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                   ],
                 ),
               ),
              Row(
                children: [
                  IconButton(
                     onPressed: _showAddSubjectDialog,
                     icon: Icon(Icons.add_circle_outline, color: AppColors.primaryAction),
                     tooltip: "Add Subject",
                  ),
                   IconButton(
                    onPressed: _showManualEntryDialog,
                    icon: Icon(Icons.add_rounded, color: AppColors.textSecondary),
                    tooltip: "Manual Entry",
                  ),
                ],
              )
            ],
          ),
          
          const SizedBox(height: 16),
          // Subject Chips
          if (subjects.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: subjects.map((subject) {
                   final isSelected = studyState.selectedSubjectId == subject.id;
                   return Padding(
                     padding: const EdgeInsets.only(right: 8),
                     child: ChoiceChip(
                       label: Text(subject.name),
                       selected: isSelected,
                       selectedColor: Color(subject.colorValue).withOpacity(0.3),
                       labelStyle: TextStyle(
                         color: isSelected ? Color(subject.colorValue) : AppColors.textSecondary,
                         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                       ),
                       backgroundColor: Colors.transparent,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(20),
                         side: BorderSide(
                           color: isSelected ? Color(subject.colorValue) : Colors.white.withOpacity(0.1),
                         ),
                       ),
                       onSelected: (val) {
                         if (val) ref.read(studyHoursProvider.notifier).selectSubject(subject.id);
                       },
                     ),
                   );
                }).toList(),
              ),
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
                    _formatTime(
                      // Show subject time if selected, else total
                      (selectedSubject != null ? selectedSubject.todaySeconds : studyState.totalSeconds).toInt()
                    ),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: isRunning 
                          ? (selectedSubject != null ? Color(selectedSubject.colorValue) : AppColors.secondaryAccent) 
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: -2,
                    ),
                  ),
                   Text(
                    isRunning ? "Focusing..." : (selectedSubject != null ? "Today's ${selectedSubject.name} Time" : "Total Time Today"),
                    style: TextStyle(
                      fontSize: 14,
                      color: isRunning 
                          ? (selectedSubject != null ? Color(selectedSubject.colorValue) : AppColors.secondaryAccent) 
                          : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Timer Control
              GestureDetector(
                onTap: () {
                  if (subjects.isEmpty && !isRunning) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please create a subject first!")));
                     _showAddSubjectDialog();
                     return;
                  }
                  if (selectedSubject == null && !isRunning && subjects.isNotEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a subject!")));
                     return;
                  }
                  
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
                    color: studyState.isTimerRunning 
                        ? Colors.redAccent.withOpacity(0.1) 
                        : (selectedSubject != null ? Color(selectedSubject.colorValue) : AppColors.secondaryAccent),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (studyState.isTimerRunning 
                            ? Colors.redAccent 
                            : (selectedSubject != null ? Color(selectedSubject.colorValue) : AppColors.secondaryAccent)).withOpacity(0.3),
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
          
          const SizedBox(height: 24),
          // Partition Bar
           if (subjects.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: subjects.map((subject) {
                    final double ratio = studyState.totalSeconds > 0 
                        ? (subject.todaySeconds / studyState.totalSeconds) 
                        : 0;
                     if (ratio <= 0) return const SizedBox.shrink();
                     return Expanded(
                       flex: (ratio * 1000).toInt(),
                       child: Container(color: Color(subject.colorValue)),
                     );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

