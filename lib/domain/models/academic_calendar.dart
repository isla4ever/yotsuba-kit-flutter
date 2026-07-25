enum AcademicDayKind { holiday, makeUp }

class AcademicDayOverride {
  const AcademicDayOverride({
    required this.dateKey,
    required this.kind,
    required this.name,
    this.sourceWeekday,
    this.isManual = true,
  });

  final String dateKey;
  final AcademicDayKind kind;
  final String name;
  final int? sourceWeekday;
  final bool isManual;

  DateTime get date => DateTime.parse(dateKey);

  AcademicDayOverride copyWith({
    AcademicDayKind? kind,
    String? name,
    int? sourceWeekday,
    bool clearSourceWeekday = false,
    bool? isManual,
  }) {
    return AcademicDayOverride(
      dateKey: dateKey,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      sourceWeekday: clearSourceWeekday
          ? null
          : sourceWeekday ?? this.sourceWeekday,
      isManual: isManual ?? this.isManual,
    );
  }

  Map<String, Object?> toJson() => {
    'dateKey': dateKey,
    'kind': kind.name,
    'name': name,
    'sourceWeekday': sourceWeekday,
    'isManual': isManual,
  };

  factory AcademicDayOverride.fromJson(Map<String, dynamic> json) {
    return AcademicDayOverride(
      dateKey: json['dateKey'] as String,
      kind: AcademicDayKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => AcademicDayKind.holiday,
      ),
      name: json['name'] as String? ?? '日历调整',
      sourceWeekday: json['sourceWeekday'] as int?,
      isManual: json['isManual'] as bool? ?? true,
    );
  }
}
