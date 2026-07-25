class DayTask {
  const DayTask({
    required this.id,
    required this.dateKey,
    required this.title,
    this.completed = false,
  });

  final String id;
  final String dateKey;
  final String title;
  final bool completed;

  DayTask copyWith({String? dateKey, String? title, bool? completed}) {
    return DayTask(
      id: id,
      dateKey: dateKey ?? this.dateKey,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'dateKey': dateKey,
    'title': title,
    'completed': completed,
  };

  factory DayTask.fromJson(Map<String, dynamic> json) {
    return DayTask(
      id: json['id'] as String,
      dateKey: json['dateKey'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
