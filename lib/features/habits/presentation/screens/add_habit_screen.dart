import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../presentation/providers/habit_provider.dart';
import '../../../../core/providers/navigation_provider.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _nameController = TextEditingController();
  final _customFrequencyController = TextEditingController(); // New
  
  // State for selections
  String _selectedFrequency = 'Daily';
  IconData _selectedIcon = Icons.book;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    final title = _nameController.text.trim();
    if (title.isNotEmpty) {
      String frequency = _selectedFrequency;
      if (_selectedFrequency == 'Custom') {
        frequency = _customFrequencyController.text.trim();
        if (frequency.isEmpty) frequency = "Custom"; // Fallback
      }

      await ref.read(habitProvider.notifier).addHabit(
        title, 
        frequency: frequency,
        iconCode: _selectedIcon.codePoint,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Habit Created!")),
        );
        _nameController.clear();
        // Navigate back to Dashboard
        ref.read(navigationProvider.notifier).setIndex(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("New Habit"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            onPressed: _saveHabit,
            icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What do you want to achieve?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 32),
            
            // Habit Name Input
            Text("HABIT NAME", style: _labelStyle(context)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "e.g., Read 10 pages",
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Frequency
            Text("FREQUENCY", style: _labelStyle(context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildChip(context, "Daily"),
                _buildChip(context, "Weekly"),
                _buildChip(context, "21 Days"),
                _buildChip(context, "Monthly"),
                _buildChip(context, "Custom"),
              ],
            ),
            if (_selectedFrequency == 'Custom') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customFrequencyController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Enter frequency (e.g. Every 3 days)",
                  hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
 
            // Icon Selection
            Text("ICON", style: _labelStyle(context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildIconChoice(context, Icons.book), // Reading
                _buildIconChoice(context, Icons.menu_book), // Reading Alt
                _buildIconChoice(context, Icons.no_food), // No Junk Food
                _buildIconChoice(context, Icons.local_pizza), // Fast Food
                _buildIconChoice(context, Icons.directions_run), // Running
                _buildIconChoice(context, Icons.fitness_center), // Gym
                _buildIconChoice(context, Icons.water_drop), // Hydration
                _buildIconChoice(context, Icons.bed), // Sleep
                _buildIconChoice(context, Icons.self_improvement), // Meditation
                _buildIconChoice(context, Icons.code), // Coding
                _buildIconChoice(context, Icons.work), // Work
                _buildIconChoice(context, Icons.music_note), // Music
                _buildIconChoice(context, Icons.brush), // Art
                _buildIconChoice(context, Icons.savings), // Saving Money
                _buildIconChoice(context, Icons.phonelink_erase), // Detox
              ],
            ),
            
            const SizedBox(height: 48),
            
            // Done Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) => TextStyle(
    color: Theme.of(context).textTheme.bodyMedium?.color,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  Widget _buildChip(BuildContext context, String label) {
    final isSelected = _selectedFrequency == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFrequency = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildIconChoice(BuildContext context, IconData icon) {
    final isSelected = _selectedIcon == icon;
    return GestureDetector(
      onTap: () => setState(() => _selectedIcon = icon),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Theme.of(context).cardTheme.color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
