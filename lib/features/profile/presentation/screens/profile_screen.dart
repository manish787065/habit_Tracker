import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/logic/badge_logic.dart';
import '../../../home/presentation/providers/study_hours_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../gamification/domain/gamification_types.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationDaily = true;
  bool _notificationHabits = true;

  void _showEditProfileDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Full Name"),
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

    if (user == null) return const SizedBox(); // Should not happen

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
           IconButton(
             icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.secondary),
             onPressed: () {
               ref.read(authProvider.notifier).logout();
               Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (c) => const LoginScreen()), (route) => false);
             },
           )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
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
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.profession,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                    onPressed: () => _showEditProfileDialog(user),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings
            _sectionHeader(context, "Settings"),
            const SizedBox(height: 16),
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
              "Language",
              trailing: DropdownButton<String>(
                value: "English",
                dropdownColor: Theme.of(context).cardTheme.color,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                underline: const SizedBox(),
                items: ["English", "Spanish", "Hindi"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {}, // Mock
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
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
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
             _buildSettingTile(
              context,
              "Habit Reminders",
              trailing: Switch(
                value: _notificationHabits,
                onChanged: (val) => setState(() => _notificationHabits = val),
                 activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 32),
            
            // Badges / Achievements
             _sectionHeader(context, "Today's Achievement"),
             const SizedBox(height: 16),
             Consumer(
               builder: (context, ref, _) {
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
                     child: Text("Study for at least 1 hour to unlock a badge!", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
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
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: info.color.withOpacity(0.2),
                           shape: BoxShape.circle,
                         ),
                         child: Icon(info.icon, color: info.color, size: 32),
                       ),
                       const SizedBox(width: 16),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             info.name,
                             style: TextStyle(
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                               color: info.color,
                             ),
                           ),
                           Text(
                             "Unlocked at ${studyState.totalHours.toStringAsFixed(1)} hrs",
                             style: TextStyle(
                               color: Theme.of(context).textTheme.bodyLarge?.color,
                               fontSize: 12,
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                 );
               }
             ),
             
            const SizedBox(height: 32),
             _sectionHeader(context, "Badge Collection"),
             const SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _buildBadgeItem(context, BadgeType.streakMaintainer),
                 _buildBadgeItem(context, BadgeType.warrior),
                 _buildBadgeItem(context, BadgeType.focused),
                 _buildBadgeItem(context, BadgeType.godLevel),
               ].take(3).toList(), 
             ),

            const SizedBox(height: 32),
            _sectionHeader(context, "Study History"),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                // We're already watching studyState at the top of build, so this rebuilds on timer tick.
                // That's good for live updates of "Today".
                final history = ref.read(studyHoursProvider.notifier).getHistory();
                
                if (history.isEmpty) {
                   return Text("No study history yet.", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)));
                }

                return Column(
                  children: history.map((dayData) {
                    final dateStr = dayData['date'] as String;
                    final hours = dayData['hours'] as double;
                    final dateObj = DateTime.parse(dateStr);
                    // Simple date formatting
                    final formattedDate = "${dateObj.day}/${dateObj.month}/${dateObj.year}";
                    final isToday = dateStr == DateTime.now().toIso8601String().split('T')[0];
                    
                    final badgeForDay = BadgeLogic.getBadgeForHours(hours);
                    final badgeInfo = BadgeLogic.getInfo(badgeForDay);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: badgeInfo.color.withOpacity(0.1),
                               shape: BoxShape.circle,
                             ),
                             child: Icon(badgeInfo.icon, color: badgeInfo.color, size: 20),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Text(
                               isToday ? "Today" : formattedDate,
                               style: TextStyle(
                                 fontWeight: FontWeight.bold,
                                 color: Theme.of(context).textTheme.bodyLarge?.color,
                               ),
                             ),
                           ),
                           Text(
                             "${hours.toStringAsFixed(1)} hrs",
                             style: TextStyle(
                               color: Theme.of(context).colorScheme.primary,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ],
                      ),
                    );
                  }).toList(),
                );
              }
            ),

            const SizedBox(height: 32),
            _sectionHeader(context, "Challenges (Habit Strength)"),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final habits = ref.watch(habitProvider);
                if (habits.isEmpty) {
                   return Text(
                     "No habits created yet. Start your journey!", 
                     style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5))
                   );
                }
                return Column(
                  children: habits.map((habit) {
                    // Logic: Calculate consistency based on frequency
                    final now = DateTime.now();
                    double progress = 0.0;
                    String periodLabel = "Last 30 Days";
                    String titleLabel = "Consistency";

                    bool checkDate(DateTime d) {
                      return habit.completedDays.any((completed) => 
                        completed.year == d.year && completed.month == d.month && completed.day == d.day
                      );
                    }

                    if (habit.frequency == '21 Days') {
                      // Special Case: 21 Day Challenge Logic
                      // We assume this implies a "Daily" habit with a goal of 21 days streak.
                      titleLabel = "21 Day Challenge";
                      int streak = habit.streak; // Uses the daily streak logic from model
                      progress = (streak / 21.0).clamp(0.0, 1.0);
                      periodLabel = "$streak / 21 Days Streak";
                    } else if (habit.frequency == 'Weekly') {
                      titleLabel = "Weekly Consistency";
                      periodLabel = "Last 4 Weeks";
                      int weeksHit = 0;
                      for(int i=0; i<4; i++) {
                         bool hit = false;
                         for(int d=0; d<7; d++) {
                            if (checkDate(now.subtract(Duration(days: i*7 + d)))) hit = true;
                         }
                         if (hit) weeksHit++;
                      }
                      progress = weeksHit / 4.0;
                    } else if (habit.frequency == 'Monthly') {
                      titleLabel = "Monthly Consistency";
                      periodLabel = "Last 6 Months";
                      int monthsHit = 0;
                      for(int i=0; i<6; i++) {
                         bool hit = false;
                         for(int d=0; d<30; d++) {
                             if (checkDate(now.subtract(Duration(days: i*30 + d)))) hit = true;
                         }
                         if (hit) monthsHit++;
                      }
                      progress = monthsHit / 6.0;
                    } else {
                      // Daily or Custom
                      titleLabel = "Monthly Consistency";
                      if (habit.frequency != 'Daily') titleLabel = "${habit.frequency} Consistency";
                      
                      // Check last 30 days
                      int count = 0;
                      for (int i = 0; i < 30; i++) {
                         if (checkDate(now.subtract(Duration(days: i)))) count++;
                      }
                      progress = (count / 30.0).clamp(0.0, 1.0);
                      periodLabel = "Last 30 Days";
                    }
                    
                    return Column(
                      children: [
                        _buildChallengeCard(
                          context, 
                          habit.title, 
                          (habit.frequency == '21 Days') ? periodLabel : "Score: ${(progress * 100).toInt()}% ($periodLabel)", 
                          progress
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList(),
                );
              }
            ),

          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, String title, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildBadgeItem(BuildContext context, BadgeType type) {
    final info = BadgeLogic.getInfo(type);
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: info.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(info.icon, color: info.color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(info.name.split(' ').first, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ],
    );
  }

  Widget _buildChallengeCard(BuildContext context, String title, String subtitle, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              Text("${(progress * 100).toInt()}%", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.secondaryAccent.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
        ],
      ),
    );
  }
}
