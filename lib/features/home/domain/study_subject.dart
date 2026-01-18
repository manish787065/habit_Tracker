import 'package:flutter/material.dart';

class StudySubject {
  final String id;
  final String name;
  final int colorValue; // Store int for Hive compatibility
  final double totalSeconds; // All time or today? Likely today based on requirements. 
  // User asked for "track kar sakta hai kitna padha" and "daily targets".
  // Usually study timers track "Today" separately from "Total".
  // Let's track today's seconds here for the partition view.
  final double todaySeconds;
  final double dailyTargetSeconds;

  StudySubject({
    required this.id,
    required this.name,
    required this.colorValue,
    this.totalSeconds = 0,
    this.todaySeconds = 0,
    this.dailyTargetSeconds = 3600, // Default 1 hour
  });

  Color get color => Color(colorValue);

  StudySubject copyWith({
    String? name,
    int? colorValue,
    double? totalSeconds,
    double? todaySeconds,
    double? dailyTargetSeconds,
  }) {
    return StudySubject(
      id: this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      todaySeconds: todaySeconds ?? this.todaySeconds,
      dailyTargetSeconds: dailyTargetSeconds ?? this.dailyTargetSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'totalSeconds': totalSeconds,
      'todaySeconds': todaySeconds,
      'dailyTargetSeconds': dailyTargetSeconds,
    };
  }

  factory StudySubject.fromMap(Map<dynamic, dynamic> map) {
    return StudySubject(
      id: map['id'],
      name: map['name'],
      colorValue: map['colorValue'],
      totalSeconds: map['totalSeconds']?.toDouble() ?? 0.0,
      todaySeconds: map['todaySeconds']?.toDouble() ?? 0.0,
      dailyTargetSeconds: map['dailyTargetSeconds']?.toDouble() ?? 3600.0,
    );
  }
}
