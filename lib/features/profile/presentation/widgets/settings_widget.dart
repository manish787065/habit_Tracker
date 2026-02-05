import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/logic/badge_logic.dart';
import '../../../home/presentation/providers/study_hours_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../gamification/domain/gamification_types.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';

class SettingsWidget extends ConsumerStatefulWidget {
  const SettingsWidget({super.key});

  @override
  ConsumerState<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends ConsumerState<SettingsWidget> {
  bool _notificationDaily = true;
  bool _notificationHabits = true;

  void _showEditProfileDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text("Edit Profile", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: "Full Name",
            labelStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).updateName(nameController.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
                   (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    if (user == null) return const SizedBox();

    return Column(
      children: [
        // Profile Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.secondaryAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, size: 30, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      user.profession,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 20),
                onPressed: () => _showEditProfileDialog(user),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _sectionHeader(context, "Settings"),
        const SizedBox(height: 12),
        _buildSettingTile(
          context,
          "Dark Mode",
          trailing: Switch(
            value: isDark,
            onChanged: (val) {
              ref.read(themeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        _buildSettingTile(
          context,
          "Reward Theme",
          trailing: Consumer(
            builder: (context, ref, _) {
              final currentTheme = ref.watch(gamificationProvider);
              return DropdownButton<GamificationTheme>(
                value: currentTheme,
                dropdownColor: Theme.of(context).cardTheme.color,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13),
                underline: const SizedBox(),
                items: GamificationTheme.values.map((theme) => DropdownMenuItem(
                  value: theme, 
                  child: Text("${theme.emoji} ${theme.displayName}"),
                )).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(gamificationProvider.notifier).setTheme(val);
                  }
                },
              );
            }
          ),
        ),
        _buildSettingTile(
          context,
          "Daily Reminders",
          trailing: Switch(
            value: _notificationDaily,
            onChanged: (val) => setState(() => _notificationDaily = val),
             activeColor: Theme.of(context).colorScheme.primary,
          ),
        ),

        const SizedBox(height: 24),
        _sectionHeader(context, "Achievement"),
        const SizedBox(height: 12),
        _buildAchievement(context),
      ],
    );
  }

  Widget _buildAchievement(BuildContext context) {
    final studyState = ref.watch(studyHoursProvider);
    final badgeType = BadgeLogic.getBadgeForHours(studyState.totalHours);
    final info = BadgeLogic.getInfo(badgeType);
    
    if (badgeType == BadgeType.none) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "Study for at least 1 hour to unlock a badge!", 
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 13)
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(info.icon, color: info.color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: info.color),
              ),
              Text(
                "Unlocked at ${studyState.totalHours.toStringAsFixed(1)} hrs",
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, String title, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
