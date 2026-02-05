import 'dart:math';

class Challenge {
  final String id;
  final String title;
  final String code;
  final int maxParticipants;
  final DateTime startTime;
  final DateTime endTime;
  final List<ChallengeParticipant> participants;
  final String creatorId;

  Challenge({
    required this.id,
    required this.title,
    required this.code,
    required this.maxParticipants,
    required this.startTime,
    required this.endTime,
    required this.participants,
    required this.creatorId,
  });

  bool get isActive => DateTime.now().isBefore(endTime);

  static String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'maxParticipants': maxParticipants,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'participants': participants.map((e) => e.toMap()).toList(),
      'creatorId': creatorId,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'],
      title: map['title'],
      code: map['code'],
      maxParticipants: map['maxParticipants'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      participants: (map['participants'] as List)
          .map((e) => ChallengeParticipant.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      creatorId: map['creatorId'],
    );
  }
}

class ChallengeParticipant {
  final String id;
  final String name;
  final double initialHours; // Hours when joined
  final double currentHours; // Total hours since joined

  ChallengeParticipant({
    required this.id,
    required this.name,
    required this.initialHours,
    required this.currentHours,
  });

  double get contribution => max(0, currentHours - initialHours);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initialHours': initialHours,
      'currentHours': currentHours,
    };
  }

  factory ChallengeParticipant.fromMap(Map<String, dynamic> map) {
    return ChallengeParticipant(
      id: map['id'],
      name: map['name'],
      initialHours: map['initialHours'] ?? 0.0,
      currentHours: map['currentHours'] ?? 0.0,
    );
  }
}
