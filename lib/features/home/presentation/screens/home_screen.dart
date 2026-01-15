import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../stats/presentation/screens/stats_screen.dart';
import '../../../habits/presentation/screens/add_habit_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../widgets/day_counter_widget.dart';
import '../widgets/study_hours_widget.dart';
import '../widgets/habit_list_widget.dart';
import '../widgets/daily_rating_widget.dart';
import '../widgets/todays_thought_widget.dart';
import '../../../todo/presentation/widgets/todo_widget.dart';
import '../../../pomodoro/presentation/widgets/pomodoro_widget.dart';
import '../../../social/presentation/screens/challenge_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime? _lastPressedAt;
  late ScrollController _scrollController;
  bool _isNavVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isNavVisible) setState(() => _isNavVisible = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isNavVisible) setState(() => _isNavVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationProvider);

    final List<Widget> pages = [
      DashboardView(scrollController: _scrollController),
      const AddHabitScreen(),
      const StatsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          Fluttertoast.showToast(msg: "Press back again to exit");
        } else {
           SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true, // Allow body to go behind bottom nav
        body: Stack(
          children: [
            pages[selectedIndex],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: (_isNavVisible && MediaQuery.of(context).viewInsets.bottom == 0) ? 80 + MediaQuery.of(context).padding.bottom : 0,
                child: Wrap(
                  children: [_buildBottomNav(selectedIndex)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(int selectedIndex) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 80 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color?.withOpacity(0.7), // Semi-transparent for glass effect
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(Icons.home_rounded, 0, selectedIndex),
              _buildAddButton(),
              _buildNavIcon(Icons.bar_chart_rounded, 2, selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, int selectedIndex) {
    final isSelected = selectedIndex == index;
    return IconButton(
      icon: Icon(icon, size: 28),
      color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
      onPressed: () => ref.read(navigationProvider.notifier).setIndex(index),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryAction,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAction.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add, size: 32),
        color: AppColors.textPrimary,
        onPressed: () => ref.read(navigationProvider.notifier).setIndex(1),
      ),
    );
  }
}


class DashboardView extends ConsumerWidget {
  final ScrollController? scrollController;
  const DashboardView({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false, 
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Increased bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 32), // More spacing
            const DayCounterWidget(),
            const SizedBox(height: 24),
            const TodoWidget(),
            const SizedBox(height: 32),
            Text(
              "Your Habits",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 16),
            const HabitListWidget(),
            const SizedBox(height: 24),
            const PomodoroWidget(),
            const SizedBox(height: 24),
            const StudyHoursWidget(),
            const SizedBox(height: 16),
            _buildChallengeCard(context),
            const SizedBox(height: 24),
            const TodaysThoughtWidget(),
            const SizedBox(height: 24),
            const DailyRatingWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryAccent.withOpacity(0.8), 
              AppColors.primaryAccent.withOpacity(0.4)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Challenge",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                     Text(
                      "Compete with friends",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final greetingName = user?.name ?? "Friend";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $greetingName",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Focus on what matters.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryAction, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: AppColors.background,
              radius: 22,
              child: Icon(Icons.person, color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}    
