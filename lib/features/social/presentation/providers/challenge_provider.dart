import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/hive_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/study_hours_provider.dart';
import '../../domain/challenge.dart';

class ChallengeState {
  final List<Challenge> activeChallenges;
  final Challenge? selectedChallenge;

  ChallengeState({
    required this.activeChallenges,
    this.selectedChallenge,
  });

  ChallengeState copyWith({
    List<Challenge>? activeChallenges,
    Challenge? selectedChallenge,
  }) {
    return ChallengeState(
      activeChallenges: activeChallenges ?? this.activeChallenges,
      selectedChallenge: selectedChallenge ?? this.selectedChallenge,
    );
  }
}

class ChallengeNotifier extends StateNotifier<ChallengeState> {
  final Ref ref;

  ChallengeNotifier(this.ref) : super(ChallengeState(activeChallenges: [])) {
    _loadChallenges();
    _listenToStudyHours();
  }

  void _loadChallenges() {
    final box = HiveHelper.habits;
    final List<dynamic> raw = box.get('active_challenges', defaultValue: []);
    final challenges = raw.map((e) => Challenge.fromMap(Map<String, dynamic>.from(e))).toList();
    state = state.copyWith(activeChallenges: challenges);
  }

  void _saveChallenges() {
    final box = HiveHelper.habits;
    final list = state.activeChallenges.map((e) => e.toMap()).toList();
    box.put('active_challenges', list);
  }

  void _listenToStudyHours() {
    ref.listen(studyHoursProvider, (previous, next) {
      if (state.activeChallenges.isEmpty) return;

      final updatedChallenges = state.activeChallenges.map((challenge) {
        if (!challenge.isActive) return challenge;

        final user = ref.read(authProvider);
        if (user == null) return challenge;

        final participants = challenge.participants.map((p) {
          if (p.id == user.username) {
            return ChallengeParticipant(
              id: p.id,
              name: p.name,
              initialHours: p.initialHours,
              currentHours: next.totalHours,
            );
          }
          return p;
        }).toList();

        return Challenge(
          id: challenge.id,
          title: challenge.title,
          code: challenge.code,
          maxParticipants: challenge.maxParticipants,
          startTime: challenge.startTime,
          endTime: challenge.endTime,
          participants: participants,
          creatorId: challenge.creatorId,
        );
      }).toList();

      state = state.copyWith(activeChallenges: updatedChallenges);
      _saveChallenges();
    });
  }

  void createChallenge(String title, int participants, Duration duration) {
    final user = ref.read(authProvider);
    if (user == null) return;

    final studyState = ref.read(studyHoursProvider);
    
    final newChallenge = Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      code: Challenge.generateCode(),
      maxParticipants: participants,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(duration),
      participants: [
        ChallengeParticipant(
          id: user.username,
          name: user.name,
          initialHours: studyState.totalHours,
          currentHours: studyState.totalHours,
        )
      ],
      creatorId: user.username,
    );

    state = state.copyWith(activeChallenges: [...state.activeChallenges, newChallenge]);
    _saveChallenges();
  }

  bool joinChallenge(String code) {
    final user = ref.read(authProvider);
    if (user == null) return false;

    final studyState = ref.read(studyHoursProvider);

    int index = state.activeChallenges.indexWhere((c) => c.code.toUpperCase() == code.toUpperCase());
    if (index == -1) return false;

    var challenge = state.activeChallenges[index];
    
    // Check if user already joined
    if (challenge.participants.any((p) => p.id == user.username)) return true;

    // Check capacity
    if (challenge.participants.length >= challenge.maxParticipants) return false;

    final newParticipant = ChallengeParticipant(
      id: user.username,
      name: user.name,
      initialHours: studyState.totalHours,
      currentHours: studyState.totalHours,
    );

    final updatedParticipants = [...challenge.participants, newParticipant];
    final updatedChallenge = Challenge(
      id: challenge.id,
      title: challenge.title,
      code: challenge.code,
      maxParticipants: challenge.maxParticipants,
      startTime: challenge.startTime,
      endTime: challenge.endTime,
      participants: updatedParticipants,
      creatorId: challenge.creatorId,
    );

    final newList = [...state.activeChallenges];
    newList[index] = updatedChallenge;
    state = state.copyWith(activeChallenges: newList);
    _saveChallenges();
    return true;
  }

  void deleteChallenge(String id) {
    state = state.copyWith(
      activeChallenges: state.activeChallenges.where((c) => c.id != id).toList(),
    );
    _saveChallenges();
  }
}

final challengeProvider = StateNotifierProvider<ChallengeNotifier, ChallengeState>((ref) {
  return ChallengeNotifier(ref);
});
