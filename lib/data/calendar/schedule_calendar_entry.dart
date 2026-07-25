enum ScheduleCalendarEntryKind { course, plan, deadline }

class ScheduleCalendarEntry {
  const ScheduleCalendarEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.start,
    required this.end,
    required this.description,
    this.location = '',
    this.reminders = const [],
  });

  final String id;
  final ScheduleCalendarEntryKind kind;
  final String title;
  final DateTime start;
  final DateTime end;
  final String description;
  final String location;
  final List<Duration> reminders;
}
