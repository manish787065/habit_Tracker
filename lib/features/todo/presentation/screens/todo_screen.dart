import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/todo_provider.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Plan Your Day"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
      ),
      body: todos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 80, color: AppColors.secondaryAccent.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "No tasks yet.",
                    style: TextStyle(
                      fontSize: 18, 
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Dismissible(
                  key: Key(todo.id),
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(todoProvider.notifier).deleteTodo(todo.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Theme.of(context).cardTheme.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.secondaryAccent.withOpacity(0.2), 
                        width: 1
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: IconButton(
                        icon: Icon(
                          todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                          color: todo.isCompleted ? AppColors.primaryAction : AppColors.secondaryAccent,
                          size: 28,
                        ),
                        onPressed: () => ref.read(todoProvider.notifier).toggleTodo(todo.id),
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          color: todo.isCompleted 
                            ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5) 
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.7)),
                        onPressed: () => ref.read(todoProvider.notifier).deleteTodo(todo.id),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: AppColors.primaryAction,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Task"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter task name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(todoProvider.notifier).addTodo(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
