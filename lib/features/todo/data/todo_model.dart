
class TodoItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime date;

  TodoItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? date,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
    };
  }

  factory TodoItem.fromMap(Map<dynamic, dynamic> map) {
    return TodoItem(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
      date: DateTime.parse(map['date']),
    );
  }
}
