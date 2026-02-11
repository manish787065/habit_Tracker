import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription? _challengesSubscription;
  final Map<String, StreamSubscription> _participantsSubscriptions = {};

  ChallengeNotifier(this.ref) : super(ChallengeState(activeChallenges: [])) {
    _init();
  }

  void _init() {
    ref.listen<User?>(authProvider, (previous, next) {
      if (next == null) {
        _stopSync();
        state = state.copyWith(activeChallenges: []);
      } else {
        _startSync(next.id);
      }
    }, fireImmediately: true);

    _listenToStudyHours();
  }

  void _stopSync() {
    _challengesSubscription?.cancel();
    for (var sub in _participantsSubscriptions.values) {
      sub.cancel();
    }
    _participantsSubscriptions.clear();
  }

  void _startSync(String userId) {
    _stopSync();
    _challengesSubscription = _firestore
        .collection('challenges')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .listen((challengesSnapshot) {
      
      final currentChallenges = challengesSnapshot.docs;
      
      // Clean up stale participant listeners
      final currentIds = currentChallenges.map((doc) => doc.id).toSet();
      _participantsSubscriptions.removeWhere((id, sub) {
        if (!currentIds.contains(id)) {
          sub.cancel();
          return true;
        }
        return false;
      });

      // Map challenges and start participant listeners for new ones
      for (var challengeDoc in currentChallenges) {
        final challengeId = challengeDoc.id;
        if (!_participantsSubscriptions.containsKey(challengeId)) {
          _participantsSubscriptions[challengeId] = _firestore
              .collection('challenges')
              .doc(challengeId)
              .collection('participants')
              .snapshots()
              .listen((participantsSnapshot) {
            _updateChallengeWithParticipants(challengeId, participantsSnapshot);
          });
        }
      }

      // Initial state update with basic challenge data (participants might be empty until their listeners fire)
      final List<Challenge> updatedList = currentChallenges.map((doc) {
         final existing = state.activeChallenges.firstWhere((c) => c.id == doc.id, 
            orElse: () => Challenge.fromMap(doc.data() as Map<String, dynamic>));
         return Challenge.fromMap(doc.data() as Map<String, dynamic>, participants: existing.participants);
      }).toList();
      
      state = state.copyWith(activeChallenges: updatedList);
    });
  }

  void _updateChallengeWithParticipants(String challengeId, QuerySnapshot participantsSnapshot) {
    final participants = participantsSnapshot.docs
        .map((doc) => ChallengeParticipant.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    state = state.copyWith(
      activeChallenges: state.activeChallenges.map((c) {
        if (c.id == challengeId) {
          return Challenge(
            id: c.id,
            title: c.title,
            code: c.code,
            maxParticipants: c.maxParticipants,
            startTime: c.startTime,
            endTime: c.endTime,
            participants: participants,
            participantIds: c.participantIds,
            creatorId: c.creatorId,
          );
        }
        return c;
      }).toList(),
    );
  }

  void _listenToStudyHours() {
    ref.listen(studyHoursProvider, (previous, next) {
      final user = ref.read(authProvider);
      if (user == null || state.activeChallenges.isEmpty) return;

      for (var challenge in state.activeChallenges) {
        if (challenge.isActive) {
          _firestore
              .collection('challenges')
              .doc(challenge.id)
              .collection('participants')
              .doc(user.id) // Use UID here
              .update({'currentHours': next.totalHours});
        }
      }
    });
  }

  Future<void> createChallenge(String title, int participants, Duration duration) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final studyState = ref.read(studyHoursProvider);
    final challengeId = DateTime.now().millisecondsSinceEpoch.toString();
    final code = Challenge.generateCode();

    final newChallenge = Challenge(
      id: challengeId,
      title: title,
      code: code,
      maxParticipants: participants,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(duration),
      participants: [], // Will be synced
      participantIds: [user.id],
      creatorId: user.id,
    );

    await _firestore.collection('challenges').doc(challengeId).set(newChallenge.toMap());
    
    // Add creator as first participant
    final participant = ChallengeParticipant(
      id: user.id,
      name: user.name,
      initialHours: studyState.totalHours,
      currentHours: studyState.totalHours,
    );

    await _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('participants')
        .doc(user.id)
        .set(participant.toMap());
  }

  Future<bool> joinChallenge(String code) async {
    final user = ref.read(authProvider);
    if (user == null) return false;

    final studyState = ref.read(studyHoursProvider);

    // Find challenge by code
    final query = await _firestore
        .collection('challenges')
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;
    
    final doc = query.docs.first;
    final challenge = Challenge.fromMap(doc.data());

    if (challenge.participantIds.contains(user.id)) return true;
    if (challenge.participantIds.length >= challenge.maxParticipants) return false;

    // Join
    final newParticipant = ChallengeParticipant(
      id: user.id,
      name: user.name,
      initialHours: studyState.totalHours,
      currentHours: studyState.totalHours,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.update(doc.reference, {
        'participantIds': FieldValue.arrayUnion([user.id])
      });
      transaction.set(
        doc.reference.collection('participants').doc(user.id),
        newParticipant.toMap(),
      );
    });

    return true;
  }

  Future<void> deleteChallenge(String id) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    // Only creator can delete for now, or just remove self?
    // Requirement says "delete", so let's assume full deletion for simplicity if creator
    final challenge = state.activeChallenges.firstWhere((c) => c.id == id);
    if (challenge.creatorId == user.id) {
        await _firestore.collection('challenges').doc(id).delete();
        // Sub-collections aren't deleted automatically in Firestore, but they won't show up in queries
    } else {
        // Just leave
        await _firestore.collection('challenges').doc(id).update({
            'participantIds': FieldValue.arrayRemove([user.id])
        });
        await _firestore.collection('challenges').doc(id).collection('participants').doc(user.id).delete();
    }
  }

  @override
  void dispose() {
    _stopSync();
    super.dispose();
  }
}

final challengeProvider = StateNotifierProvider<ChallengeNotifier, ChallengeState>((ref) {
  return ChallengeNotifier(ref);
});
