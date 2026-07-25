import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';

void main() {
  const oddCourse = Course(
    id: 'odd',
    name: 'Odd week course',
    teacher: 'Teacher',
    room: 'Room',
    weekday: 1,
    startSection: 1,
    endSection: 2,
    startWeek: 1,
    endWeek: 16,
    pattern: WeekPattern.odd,
    colorValue: 0xFF000000,
  );

  test('filters week patterns correctly', () {
    expect(oddCourse.occursInWeek(1), isTrue);
    expect(oddCourse.occursInWeek(2), isFalse);
    expect(oddCourse.occursInWeek(17), isFalse);
  });

  test('maps dates to teaching weeks', () {
    final termStart = DateTime(2026, 2, 23);
    expect(ScheduleEngine.currentWeek(termStart, DateTime(2026, 2, 23), 18), 1);
    expect(ScheduleEngine.currentWeek(termStart, DateTime(2026, 3, 9), 18), 3);
  });
}
