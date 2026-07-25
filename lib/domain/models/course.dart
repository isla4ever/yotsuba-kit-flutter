enum WeekPattern { every, odd, even }

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.room,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.startWeek,
    required this.endWeek,
    required this.colorValue,
    this.pattern = WeekPattern.every,
    this.isCustom = false,
    this.materials = const [],
  });

  final String id;
  final String name;
  final String teacher;
  final String room;
  final int weekday;
  final int startSection;
  final int endSection;
  final int startWeek;
  final int endWeek;
  final WeekPattern pattern;
  final int colorValue;
  final bool isCustom;
  final List<String> materials;

  Course copyWith({
    String? name,
    String? teacher,
    String? room,
    int? weekday,
    int? startSection,
    int? endSection,
    int? startWeek,
    int? endWeek,
    WeekPattern? pattern,
    int? colorValue,
    bool? isCustom,
    List<String>? materials,
  }) {
    return Course(
      id: id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      weekday: weekday ?? this.weekday,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      startWeek: startWeek ?? this.startWeek,
      endWeek: endWeek ?? this.endWeek,
      pattern: pattern ?? this.pattern,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
      materials: materials ?? this.materials,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'teacher': teacher,
    'room': room,
    'weekday': weekday,
    'startSection': startSection,
    'endSection': endSection,
    'startWeek': startWeek,
    'endWeek': endWeek,
    'pattern': pattern.name,
    'colorValue': colorValue,
    'isCustom': isCustom,
    'materials': materials,
  };

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      teacher: json['teacher'] as String? ?? '',
      room: json['room'] as String? ?? '',
      weekday: json['weekday'] as int,
      startSection: json['startSection'] as int,
      endSection: json['endSection'] as int,
      startWeek: json['startWeek'] as int,
      endWeek: json['endWeek'] as int,
      pattern: WeekPattern.values.firstWhere(
        (value) => value.name == json['pattern'],
        orElse: () => WeekPattern.every,
      ),
      colorValue: json['colorValue'] as int,
      isCustom: json['isCustom'] as bool? ?? false,
      materials: (json['materials'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  bool occursInWeek(int week) {
    if (week < startWeek || week > endWeek) {
      return false;
    }
    return switch (pattern) {
      WeekPattern.every => true,
      WeekPattern.odd => week.isOdd,
      WeekPattern.even => week.isEven,
    };
  }

  String get weekLabel {
    final patternLabel = switch (pattern) {
      WeekPattern.every => '',
      WeekPattern.odd => ' · 单周',
      WeekPattern.even => ' · 双周',
    };
    return '$startWeek-$endWeek周$patternLabel';
  }
}

class CourseTime {
  const CourseTime(this.start, this.end);

  final String start;
  final String end;
}

const standardCourseTimes = <CourseTime>[
  CourseTime('08:00', '08:45'),
  CourseTime('08:55', '09:40'),
  CourseTime('10:00', '10:45'),
  CourseTime('10:55', '11:40'),
  CourseTime('14:30', '15:15'),
  CourseTime('15:25', '16:10'),
  CourseTime('16:20', '17:05'),
  CourseTime('17:15', '18:00'),
  CourseTime('18:10', '18:55'),
  CourseTime('19:30', '20:15'),
  CourseTime('20:25', '21:10'),
  CourseTime('21:20', '22:05'),
];

const summerCourseTimes = <CourseTime>[
  CourseTime('08:00', '08:45'),
  CourseTime('08:55', '09:40'),
  CourseTime('10:00', '10:45'),
  CourseTime('10:55', '11:40'),
  CourseTime('15:00', '15:45'),
  CourseTime('15:55', '16:40'),
  CourseTime('16:50', '17:35'),
  CourseTime('17:45', '18:30'),
  CourseTime('18:40', '19:25'),
  CourseTime('19:35', '20:20'),
  CourseTime('20:30', '21:15'),
  CourseTime('21:25', '22:10'),
];

const courseTimes = standardCourseTimes;
