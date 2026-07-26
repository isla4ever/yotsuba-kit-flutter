import 'package:flutter/material.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

void main() => runApp(const DemoApp());

const demoCourses = <YsCourse>[
  YsCourse(id: 'math', name: '高等数学', location: '教1-201', weekday: 1, startSection: 1, endSection: 2, startWeek: 1, endWeek: 20),
  YsCourse(id: 'ds', name: '数据结构', location: '教2-105', weekday: 1, startSection: 5, endSection: 6, startWeek: 1, endWeek: 20),
  YsCourse(id: 'en', name: '大学英语', location: '外语楼302', weekday: 2, startSection: 3, endSection: 4, startWeek: 1, endWeek: 20),
  YsCourse(id: 'pe', name: '体育（单周）', location: '东操场', weekday: 4, startSection: 1, endSection: 2, startWeek: 1, endWeek: 16, parity: YsWeekParity.odd),
  YsCourse(id: 'la', name: '线性代数（双周）', location: '教1-305', weekday: 4, startSection: 1, endSection: 2, startWeek: 2, endWeek: 16, parity: YsWeekParity.even),
  YsCourse(id: 'phy', name: '大学物理', location: '理科楼210', weekday: 5, startSection: 3, endSection: 4, startWeek: 1, endWeek: 16),
];

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  int week = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'yotsuba_schedule_kit demo',
      home: Scaffold(
        appBar: AppBar(
          title: Text('第 $week 周'),
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => week = (week - 1).clamp(1, 20)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => week = (week + 1).clamp(1, 20)),
            ),
          ],
        ),
        body: YsWeekTimetable(
          week: week,
          courses: demoCourses,
          termStart: DateTime(2026, 7, 20),
          onWeekRequested: (direction) =>
              setState(() => week = (week + direction).clamp(1, 20)),
          onCourseTap: (course, stack) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(course.course.name))),
        ),
      ),
    );
  }
}
