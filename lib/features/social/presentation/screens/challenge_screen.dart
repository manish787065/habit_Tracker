import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/challenge_provider.dart';
import '../../domain/challenge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  final _joinCodeController = TextEditingController();

  void _showCreateChallengeDialog() {
    final titleController = TextEditingController();
    int participants = 2;
    int durationHours = 24;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text("Create Challenge", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    labelText: "Challenge Title",
                    hintText: "e.g., Study Marathon",
                  ),
                ),
                const SizedBox(height: 20),
                Text("Participants: $participants", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                Slider(
                  value: participants.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  onChanged: (val) => setDialogState(() => participants = val.toInt()),
                ),
                const SizedBox(height: 20),
                Text("Duration: ${durationHours}h", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                Slider(
                  value: durationHours.toDouble(),
                  min: 1,
                  max: 168, // 1 week
                  divisions: 167,
                  onChanged: (val) => setDialogState(() => durationHours = val.toInt()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  ref.read(challengeProvider.notifier).createChallenge(
                    titleController.text.trim(),
                    participants,
                    Duration(hours: durationHours),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinChallengeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text("Join Challenge", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: TextField(
          controller: _joinCodeController,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            labelText: "Enter 6-digit Code",
            hintText: "e.g., AB1234",
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final success = ref.read(challengeProvider.notifier).joinChallenge(_joinCodeController.text.trim());
              if (success) {
                Navigator.pop(context);
                _joinCodeController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid code or challenge full")));
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(challengeProvider);
    final activeChallenges = challengeState.activeChallenges;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (activeChallenges.isEmpty)
            _buildEmptyState()
          else
            Expanded(child: _buildChallengesList(activeChallenges)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Challenges",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              "Compete with friends",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: _showJoinChallengeDialog,
              icon: Icon(Icons.group_add_outlined, color: AppColors.primaryAction),
            ),
            IconButton(
              onPressed: _showCreateChallengeDialog,
              icon: Icon(Icons.add_circle_outline, color: AppColors.primaryAction),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.military_tech_outlined, size: 80, color: AppColors.primaryAction.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              "No Active Challenges",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Create a challenge and invite friends\nto compete in study hours!",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateChallengeDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Create Challenge", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAction,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesList(List<Challenge> challenges) {
    return ListView.builder(
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final timeLeft = challenge.endTime.difference(DateTime.now());
    final hours = timeLeft.inHours;
    final mins = timeLeft.inMinutes % 60;
    final currentUser = ref.watch(authProvider);
    final isCreator = challenge.creatorId == currentUser?.username;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryAction.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: challenge.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Challenge code copied to clipboard!")),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAction.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        challenge.code,
                        style: TextStyle(
                          color: AppColors.primaryAction,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  if (isCreator)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Theme.of(context).cardTheme.color,
                            title: const Text("Delete Challenge?"),
                            content: const Text("This action cannot be undone."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                              TextButton(
                                onPressed: () {
                                  ref.read(challengeProvider.notifier).deleteChallenge(challenge.id);
                                  Navigator.pop(context);
                                },
                                child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                challenge.isActive ? "$hours h ${mins}m left" : "Finished",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                "${challenge.participants.length}/${challenge.maxParticipants}",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 32),
          ...challenge.participants.asMap().entries.map((entry) {
            final p = entry.value;
            final isMe = p.id == currentUser?.username;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isMe ? AppColors.primaryAction : AppColors.primaryAction.withOpacity(0.2),
                    child: Text(p.name[0], style: TextStyle(fontSize: 10, color: isMe ? Colors.white : AppColors.primaryAction)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isMe ? "${p.name} (You)" : p.name, 
                      style: TextStyle(fontSize: 14, fontWeight: isMe ? FontWeight.bold : FontWeight.normal)
                    ),
                  ),
                  Text(
                    "+${p.contribution.toStringAsFixed(1)} h",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAction,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
