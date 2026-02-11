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
import '../../../profile/presentation/widgets/settings_widget.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../widgets/day_counter_widget.dart';
import '../widgets/study_hours_widget.dart';
import '../widgets/habit_list_widget.dart';
import '../widgets/habit_list_widget.dart';
import '../../../todo/presentation/widgets/todo_widget.dart';
import '../../../pomodoro/presentation/widgets/pomodoro_widget.dart';
import '../../../social/presentation/screens/challenge_screen.dart';
import '../../../gamification/presentation/widgets/point_listener_wrapper.dart';
import '../widgets/yearly_consistency_graph.dart';
import 'pomodoro_screen.dart';
import 'shining_off_screen.dart';
import '../widgets/main_drawer.dart';

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
    // Auto-hide listener removed for stability
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // _onScroll removed


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
        extendBody: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: const MainDrawer(),
        body: PointListenerWrapper(
          child: pages[selectedIndex],
        ),
        bottomNavigationBar: _buildBottomNav(selectedIndex),
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
              _buildNavIcon(Icons.home_rounded, "Home", 0, selectedIndex),
              _buildAddButton(selectedIndex),
              _buildNavIcon(Icons.bar_chart_rounded, "Progress", 2, selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, int index, int selectedIndex) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        ref.read(navigationProvider.notifier).setIndex(index);
        if (index == 0) {
          ref.read(dashboardCategoryProvider.notifier).state = "Home";
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(int selectedIndex) {
    final isSelected = selectedIndex == 1;
    return GestureDetector(
      onTap: () => ref.read(navigationProvider.notifier).setIndex(1),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAction,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAction.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              "New Habit",
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(dashboardCategoryProvider);
    
    return SafeArea(
      bottom: false, 
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 32), 
            
            _buildContent(selectedCategory),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String category) {
    switch (category) {
      case "Pomodoro":
        return const PomodoroWidget();
      case "Habits":
        return const HabitListWidget(); 
      case "Study":
        return const StudyHoursWidget();
      case "Daily Goals":
         return const TodoWidget(); 
      case "Challenge":
        return SizedBox(height: 400, child: const ChallengeScreen()); 
      case "Settings":
        return const SettingsWidget();
      default:
        // Case "Home" or anything else
        return Column(
          children: [
             const DayCounterWidget(),
            const SizedBox(height: 16),
            const YearlyConsistencyGraph(), // Monthly Progress
            const SizedBox(height: 24),
            
            const TodoWidget(isHome: true), // Daily Tasks
            const SizedBox(height: 24),
            
            const HabitListWidget(showTitle: true), // Ongoing Habits
            const SizedBox(height: 32),
            
            _buildShiningOffButton(context),
            const SizedBox(height: 16),
          ],
        );
    }
  }

  Widget _buildShiningOffButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShiningOffScreen()),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryAction,
                AppColors.primaryAction.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAction.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                "Shining Off",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final greetingName = user?.name ?? "Friend";

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.textPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: iconColor, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
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
                Text(
                  "Focus on what matters.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}    
