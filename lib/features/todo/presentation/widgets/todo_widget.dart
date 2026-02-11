import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/todo_provider.dart';
import '../../data/todo_model.dart';
import '../screens/todo_screen.dart';

class TodoWidget extends ConsumerStatefulWidget {
  final bool isHome;
  const TodoWidget({super.key, this.isHome = false});

  @override
  ConsumerState<TodoWidget> createState() => _TodoWidgetState();
}

class _TodoWidgetState extends ConsumerState<TodoWidget> {
  final TextEditingController _controller = TextEditingController();

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("New Task", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: TextField(
          controller: _controller,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: "What do you want to accomplish?",
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAction,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
            ),
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                ref.read(todoProvider.notifier).addTodo(_controller.text.trim());
                _controller.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoProvider);
    final todaysTodos = todos.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: AppColors.secondaryAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Daily Goals",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoScreen()));
                },
                icon: Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 20),
                tooltip: "Open Full List",
              )
            ],
          ),
          const SizedBox(height: 16),
          if (todaysTodos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 20, color: AppColors.textSecondary.withOpacity(0.3)),
                  const SizedBox(width: 8),
                  Text(
                    "Set your goals for today...",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (widget.isHome && todaysTodos.length > 5) ? 5 : todaysTodos.length, 
              itemBuilder: (context, index) {
                final todo = todaysTodos[index];
                return _buildCompactTodoItem(todo);
              },
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _showAddDialog,
              icon: Icon(Icons.add_rounded, color: AppColors.primaryAccent, size: 20),
              label: Text("Add Daily Goal", style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w600, fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: AppColors.primaryAccent.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTodoItem(TodoItem todo) {
    return InkWell(
      onTap: () => ref.read(todoProvider.notifier).toggleTodo(todo.id),
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Delete Goal"),
            content: Text("Delete '${todo.title}'?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  ref.read(todoProvider.notifier).deleteTodo(todo.id);
                  Navigator.pop(context);
                },
                child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
      splashColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: todo.isCompleted ? AppColors.secondaryAccent : Colors.transparent,
                border: Border.all(
                  color: todo.isCompleted ? AppColors.secondaryAccent : AppColors.textSecondary.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: todo.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                todo.title,
                style: TextStyle(
                  fontSize: 14,
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textSecondary,
                  color: todo.isCompleted
                      ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
