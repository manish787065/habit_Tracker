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
import '../../../gamification/presentation/widgets/point_listener_wrapper.dart';
import '../widgets/yearly_consistency_graph.dart';
import '../widgets/quick_access_bar.dart';
import 'habits_screen.dart'; // Keep for now if needed, but we use HabitListWidget
import 'study_timer_screen.dart';
import 'pomodoro_screen.dart';
import 'todo_screen.dart';

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
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true, // Allow body to go behind bottom nav
      body: PointListenerWrapper(
          child: Stack(
            children: [
              pages[selectedIndex],
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isNavVisible ? 60 + MediaQuery.of(context).padding.bottom : 0,
                  child: Wrap(
                    children: [_buildBottomNav(selectedIndex)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(int selectedIndex) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60 + MediaQuery.of(context).padding.bottom,
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
        icon: const Icon(Icons.add, size: 28),
        color: AppColors.textPrimary,
        onPressed: () => ref.read(navigationProvider.notifier).setIndex(1),
      ),
    );
  }
}


class DashboardView extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const DashboardView({super.key, this.scrollController});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  String _selectedCategory = "Overview";

  // Widget _getCategoryWidget(String category) {
  //   switch (category) {
  //     case "Pomodoro": return const PomodoroWidget(); // Need to verify
  //     case "Habits": return const HabitListWidget();
  //     case "Study": return const StudyHoursWidget();
  //     case "Tasks": return const TodoWidget(); // Need to verify
  //     case "Awards": return const ChallengeScreen(); // Might need widget wrapper
  //     default: return _buildOverview();
  //   }
  // }
  // I will implement this logic in the build method or helper.
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, 
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 12),
            
            // "Explore" text removed as requested
            
            QuickAccessBar(
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
            
            const SizedBox(height: 32), 
            
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedCategory) {
      case "Pomodoro":
        return const PomodoroWidget();
      case "Habits":
        return const HabitListWidget(); 
      case "Study":
        return const StudyHoursWidget();
      case "Tasks":
         return const TodoWidget(); 
      case "Awards":
        // Awards was mapped to ChallengeScreen. 
        // ChallengeScreen has a Scaffold, might just want the body?
        // Let's use ChallengeScreen for now but it might look nested.
        // Ideally extract body. I'll stick to Overview for now if I can't find it.
        // Actually I'll wrap it or just show Overview for now.
        return SizedBox(height: 400, child: const ChallengeScreen()); 
      case "Reflect":
        return const TodaysThoughtWidget(); // Reusing thought widget for reflect
      default:
        return Column(
          children: [
             const DayCounterWidget(),
            const SizedBox(height: 16),
            const YearlyConsistencyGraph(),
            const SizedBox(height: 24),
            
            const TodaysThoughtWidget(),
            const SizedBox(height: 24),
            const DailyRatingWidget(),
          ],
        );
    }
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
