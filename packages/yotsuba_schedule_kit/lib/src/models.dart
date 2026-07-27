/// 单双周规则。
enum YsWeekParity { every, odd, even }

enum YsCourseMaterialKind { book, device, equipment, document, other }

enum YsCourseTaskPriority { low, normal, high }

class YsCourseMaterial {
  const YsCourseMaterial({
    required this.name,
    this.id,
    this.kind = YsCourseMaterialKind.other,
    this.required = true,
    this.quantity = 1,
    this.note,
  });

  final String? id;
  final String name;
  final YsCourseMaterialKind kind;
  final bool required;
  final int quantity;
  final String? note;
}

class YsCourseBook {
  const YsCourseBook({
    required this.title,
    this.id,
    this.author,
    this.isbn,
    this.required = true,
    this.note,
  });

  final String? id;
  final String title;
  final String? author;
  final String? isbn;
  final bool required;
  final String? note;
}

class YsCourseTask {
  const YsCourseTask({
    required this.id,
    required this.title,
    this.description,
    this.dueAt,
    this.done = false,
    this.priority = YsCourseTaskPriority.normal,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueAt;
  final bool done;
  final YsCourseTaskPriority priority;
}

/// 组件库标准课程模型。
class YsCourse {
  const YsCourse({
    required this.id,
    required this.name,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.startWeek,
    required this.endWeek,
    this.parity = YsWeekParity.every,
    this.teacher,
    this.location,
    this.color,
    this.custom = false,
    this.materials = const [],
    this.materialDetails = const [],
    this.books = const [],
    this.tasks = const [],
    this.note,
    this.meta = const {},
  });

  /// 稳定唯一 id。
  final String id;
  final String name;
  final String? teacher;
  final String? location;

  /// 1-7，周一为 1。
  final int weekday;
  final int startSection;
  final int endSection;
  final int startWeek;
  final int endWeek;
  final YsWeekParity parity;

  /// ARGB 颜色值；空则由主题调色板按课程名稳定分配。
  final int? color;
  final bool custom;

  /// 旧版字符串携带清单，继续保留以兼容 0.5.x。
  final List<String> materials;
  final List<YsCourseMaterial> materialDetails;
  final List<YsCourseBook> books;
  final List<YsCourseTask> tasks;
  final String? note;

  List<YsCourseMaterial> get carryItems {
    final values = <YsCourseMaterial>[
      for (final book in books)
        YsCourseMaterial(
          id: book.id,
          name: book.title,
          kind: YsCourseMaterialKind.book,
          required: book.required,
          note: book.note,
        ),
      for (final name in materials) YsCourseMaterial(name: name),
      ...materialDetails,
    ];
    final seen = <String>{};
    return [
      for (final item in values)
        if (item.name.trim().isNotEmpty &&
            seen.add(item.name.trim().toLowerCase()))
          item,
    ];
  }

  /// 组件不会解释该数据，只在回调中原样保留。
  final Map<String, Object?> meta;

  YsCourse copyWith({
    String? id,
    String? name,
    String? teacher,
    String? location,
    int? weekday,
    int? startSection,
    int? endSection,
    int? startWeek,
    int? endWeek,
    YsWeekParity? parity,
    int? color,
    bool? custom,
    List<String>? materials,
    List<YsCourseMaterial>? materialDetails,
    List<YsCourseBook>? books,
    List<YsCourseTask>? tasks,
    String? note,
    Map<String, Object?>? meta,
  }) {
    return YsCourse(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      location: location ?? this.location,
      weekday: weekday ?? this.weekday,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      startWeek: startWeek ?? this.startWeek,
      endWeek: endWeek ?? this.endWeek,
      parity: parity ?? this.parity,
      color: color ?? this.color,
      custom: custom ?? this.custom,
      materials: materials ?? this.materials,
      materialDetails: materialDetails ?? this.materialDetails,
      books: books ?? this.books,
      tasks: tasks ?? this.tasks,
      note: note ?? this.note,
      meta: meta ?? this.meta,
    );
  }
}

class YsCourseTime {
  const YsCourseTime(this.start, this.end);

  final String start;
  final String end;
}

enum YsDayOverrideKind { makeup, holiday }

/// 调休 / 补班 / 假日。
class YsDayOverride {
  const YsDayOverride({
    required this.date,
    required this.kind,
    this.sourceWeekday,
    this.name,
  });

  /// YYYY-MM-DD。
  final String date;
  final YsDayOverrideKind kind;

  /// makeup：课程来自哪个星期（1-7）。
  final int? sourceWeekday;
  final String? name;
}

/// 某周展示用课程（补班复制后 weekday 为展示星期）。
class YsDisplayCourse {
  const YsDisplayCourse({
    required this.course,
    required this.displayId,
    required this.weekday,
    required this.active,
    this.makeupDate,
    this.makeupName,
  });

  final YsCourse course;
  final String displayId;
  final int weekday;
  final bool active;
  final String? makeupDate;
  final String? makeupName;

  bool get isMakeup => makeupDate != null;
}

class YsOverlapGroup {
  const YsOverlapGroup({
    required this.id,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.courses,
  });

  final String id;
  final int weekday;
  final int startSection;
  final int endSection;
  final List<YsDisplayCourse> courses;
}

class YsWeekModel {
  const YsWeekModel({
    required this.week,
    required this.courses,
    required this.overlapGroups,
  });

  final int week;
  final List<YsDisplayCourse> courses;
  final List<YsOverlapGroup> overlapGroups;
}

class YsDayPlan {
  const YsDayPlan({
    required this.id,
    required this.text,
    this.done = false,
  });

  final String id;
  final String text;
  final bool done;

  YsDayPlan copyWith({String? id, String? text, bool? done}) => YsDayPlan(
        id: id ?? this.id,
        text: text ?? this.text,
        done: done ?? this.done,
      );
}

typedef YsDayPlanMap = Map<String, List<YsDayPlan>>;
