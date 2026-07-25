enum PlanPriority { low, medium, high, urgent }

class CoursePlanSubtask {
  const CoursePlanSubtask({
    required this.id,
    required this.title,
    this.completed = false,
    this.position = 0,
  });

  final String id;
  final String title;
  final bool completed;
  final int position;

  CoursePlanSubtask copyWith({String? title, bool? completed, int? position}) {
    return CoursePlanSubtask(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      position: position ?? this.position,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'position': position,
  };

  factory CoursePlanSubtask.fromJson(Map<String, dynamic> json) {
    return CoursePlanSubtask(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      position: json['position'] as int? ?? 0,
    );
  }
}

class CoursePlan {
  CoursePlan({
    required this.id,
    required this.courseId,
    required this.title,
    required this.estimatedMinutes,
    this.notes = '',
    this.priority = PlanPriority.medium,
    this.completed = false,
    this.dueAt,
    this.dueSessionWeek,
    this.dueSessionWeekday,
    this.dueSessionStartSection,
    this.dueSessionEndSection,
    this.scheduledStart,
    this.scheduledEnd,
    this.reminderOffsets = const [1440, 60],
    this.calendarSyncEnabled = true,
    this.postponeCount = 0,
    this.subtasks = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String courseId;
  final String title;
  final String notes;
  final DateTime? dueAt;
  final int estimatedMinutes;
  final PlanPriority priority;
  final bool completed;
  final int? dueSessionWeek;
  final int? dueSessionWeekday;
  final int? dueSessionStartSection;
  final int? dueSessionEndSection;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final List<int> reminderOffsets;
  final bool calendarSyncEnabled;
  final int postponeCount;
  final List<CoursePlanSubtask> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  CoursePlan copyWith({
    String? title,
    String? notes,
    DateTime? dueAt,
    bool clearDueAt = false,
    int? estimatedMinutes,
    PlanPriority? priority,
    bool? completed,
    int? dueSessionWeek,
    bool clearDueSession = false,
    int? dueSessionWeekday,
    int? dueSessionStartSection,
    int? dueSessionEndSection,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    bool clearSchedule = false,
    List<int>? reminderOffsets,
    bool? calendarSyncEnabled,
    int? postponeCount,
    List<CoursePlanSubtask>? subtasks,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return CoursePlan(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      dueSessionWeek: clearDueSession
          ? null
          : dueSessionWeek ?? this.dueSessionWeek,
      dueSessionWeekday: clearDueSession
          ? null
          : dueSessionWeekday ?? this.dueSessionWeekday,
      dueSessionStartSection: clearDueSession
          ? null
          : dueSessionStartSection ?? this.dueSessionStartSection,
      dueSessionEndSection: clearDueSession
          ? null
          : dueSessionEndSection ?? this.dueSessionEndSection,
      scheduledStart: clearSchedule
          ? null
          : scheduledStart ?? this.scheduledStart,
      scheduledEnd: clearSchedule ? null : scheduledEnd ?? this.scheduledEnd,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      postponeCount: postponeCount ?? this.postponeCount,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'courseId': courseId,
    'title': title,
    'notes': notes,
    'dueAt': dueAt?.toIso8601String(),
    'estimatedMinutes': estimatedMinutes,
    'priority': priority.name,
    'completed': completed,
    'dueSessionWeek': dueSessionWeek,
    'dueSessionWeekday': dueSessionWeekday,
    'dueSessionStartSection': dueSessionStartSection,
    'dueSessionEndSection': dueSessionEndSection,
    'scheduledStart': scheduledStart?.toIso8601String(),
    'scheduledEnd': scheduledEnd?.toIso8601String(),
    'reminderOffsets': reminderOffsets,
    'calendarSyncEnabled': calendarSyncEnabled,
    'postponeCount': postponeCount,
    'subtasks': subtasks.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory CoursePlan.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) =>
        value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
    return CoursePlan(
      id: json['id'].toString(),
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      dueAt: parseDate(json['dueAt']),
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 60,
      priority: PlanPriority.values.firstWhere(
        (value) => value.name == json['priority'],
        orElse: () => PlanPriority.medium,
      ),
      completed: json['completed'] as bool? ?? false,
      dueSessionWeek: json['dueSessionWeek'] as int?,
      dueSessionWeekday: json['dueSessionWeekday'] as int?,
      dueSessionStartSection: json['dueSessionStartSection'] as int?,
      dueSessionEndSection: json['dueSessionEndSection'] as int?,
      scheduledStart: parseDate(json['scheduledStart']),
      scheduledEnd: parseDate(json['scheduledEnd']),
      reminderOffsets: (json['reminderOffsets'] as List<dynamic>? ?? const [])
          .map((item) => item as int)
          .toList(),
      calendarSyncEnabled: json['calendarSyncEnabled'] as bool? ?? true,
      postponeCount: json['postponeCount'] as int? ?? 0,
      subtasks: (json['subtasks'] as List<dynamic>? ?? const [])
          .map(
            (item) => CoursePlanSubtask.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      completedAt: parseDate(json['completedAt']),
    );
  }
}
