import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/hive_helper.dart';
import '../../data/todo_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class TodoNotifier extends StateNotifier<List<TodoItem>> {
  final Ref ref;
  StreamSubscription? _subscription;
  final _firestore = FirebaseFirestore.instance;

  TodoNotifier(this.ref) : super([]) {
    _init();
  }

  void _init() {
    ref.listen<User?>(authProvider, (previous, next) {
      if (next == null) {
        _subscription?.cancel();
        state = [];
      } else {
        _startSync(next.id);
      }
    }, fireImmediately: true);

    _loadFromHive();
  }

  void _loadFromHive() {
    final data = HiveHelper.todo.get('todoList', defaultValue: []);
    if (data is List) {
      state = data
          .map((e) => TodoItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  void _startSync(String userId) {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots()
        .listen((snapshot) {
      final todos = snapshot.docs.map((doc) => TodoItem.fromMap(doc.data() as Map<String, dynamic>)).toList();
      state = todos;
      _saveToHive(todos);
    });
  }

  Future<void> _saveToHive(List<TodoItem> todos) async {
    final mapList = todos.map((e) => e.toMap()).toList();
    await HiveHelper.todo.put('todoList', mapList);
  }

  Future<void> addTodo(String title) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newItem = TodoItem(
      id: id,
      title: title,
      date: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.id)
        .collection('tasks')
        .doc(id)
        .set(newItem.toMap());
  }

  Future<void> toggleTodo(String id) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final item = state.firstWhere((it) => it.id == id);
    final isCompleted = !item.isCompleted;

    if (isCompleted) {
      ref.read(authProvider.notifier).addPoints(5);
    } else {
      ref.read(authProvider.notifier).deductPoints(5);
    }

    await _firestore
        .collection('users')
        .doc(user.id)
        .collection('tasks')
        .doc(id)
        .update({'isCompleted': isCompleted});
  }

  Future<void> deleteTodo(String id) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.id)
        .collection('tasks')
        .doc(id)
        .delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, List<TodoItem>>((ref) {
  return TodoNotifier(ref);
});
