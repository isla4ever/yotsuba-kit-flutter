import 'package:yotsuba_schedule/core/utils/schedule_engine.dart';
import 'package:yotsuba_schedule/domain/models/course.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/domain/models/day_task.dart';
import 'package:yotsuba_schedule/domain/models/schedule_data.dart';

class MockScheduleRepository {
  const MockScheduleRepository();

  ScheduleData load() {
    final now = DateTime.now();
    final thisMonday = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    final termStart = thisMonday.subtract(const Duration(days: 35));
    final todayKey = ScheduleEngine.dateKey(now);
    final tomorrowKey = ScheduleEngine.dateKey(
      now.add(const Duration(days: 1)),
    );

    final courses = <Course>[
      const Course(
        id: 'mobile-development',
        name: '移动应用开发',
        teacher: '林老师',
        room: '海韵楼 A204',
        weekday: 1,
        startSection: 1,
        endSection: 2,
        startWeek: 1,
        endWeek: 16,
        colorValue: 0xFF2C8B7F,
        materials: ['Flutter 实战', 'Type-C 转接线'],
      ),
      const Course(
        id: 'data-visualization',
        name: '数据可视化',
        teacher: '周老师',
        room: '苍梧楼 301',
        weekday: 1,
        startSection: 5,
        endSection: 6,
        startWeek: 1,
        endWeek: 16,
        colorValue: 0xFFE56B4A,
        materials: ['平板电脑', '可视化案例册'],
      ),
      const Course(
        id: 'software-engineering',
        name: '软件工程',
        teacher: '许老师',
        room: '文通楼 208',
        weekday: 2,
        startSection: 3,
        endSection: 4,
        startWeek: 1,
        endWeek: 16,
        colorValue: 0xFF5874B8,
        materials: ['需求规格说明书'],
      ),
      const Course(
        id: 'interaction-design',
        name: '交互设计',
        teacher: '沈老师',
        room: '艺术楼 112',
        weekday: 3,
        startSection: 1,
        endSection: 2,
        startWeek: 1,
        endWeek: 15,
        pattern: WeekPattern.odd,
        colorValue: 0xFF9C6DB0,
        materials: ['速写本', '触控笔'],
      ),
      const Course(
        id: 'product-practice',
        name: '产品实践',
        teacher: '顾老师',
        room: '创新工坊',
        weekday: 3,
        startSection: 1,
        endSection: 2,
        startWeek: 2,
        endWeek: 16,
        pattern: WeekPattern.even,
        colorValue: 0xFFCA8A2C,
        materials: ['访谈提纲'],
      ),
      const Course(
        id: 'database',
        name: '数据库系统',
        teacher: '陈老师',
        room: '计算中心 401',
        weekday: 4,
        startSection: 5,
        endSection: 6,
        startWeek: 1,
        endWeek: 16,
        colorValue: 0xFF30779A,
        materials: ['实验报告'],
      ),
      const Course(
        id: 'academic-english',
        name: '学术英语',
        teacher: 'Morgan',
        room: '博雅楼 205',
        weekday: 5,
        startSection: 3,
        endSection: 4,
        startWeek: 1,
        endWeek: 16,
        colorValue: 0xFF71853E,
        materials: ['Academic Writing'],
      ),
      const Course(
        id: 'cross-platform-lab',
        name: '跨平台创作工坊',
        teacher: '叶老师',
        room: '创客空间',
        weekday: 6,
        startSection: 5,
        endSection: 6,
        startWeek: 1,
        endWeek: 16,
        colorValue: 0xFFB45C72,
        materials: ['测试手机', '充电器'],
      ),
    ];

    return ScheduleData(
      termStart: termStart,
      totalWeeks: 18,
      courses: courses,
      dayTasks: [
        DayTask(id: 'task-review', dateKey: todayKey, title: '整理今天的课堂笔记'),
        DayTask(id: 'task-team', dateKey: todayKey, title: '18:30 前确认小组分工'),
        DayTask(id: 'task-preview', dateKey: tomorrowKey, title: '预习下周移动开发章节'),
      ],
      coursePlans: [
        CoursePlan(
          id: 'plan-prototype',
          courseId: 'interaction-design',
          title: '完成高保真原型评审稿',
          dueAt: now.add(const Duration(days: 2, hours: 4)),
          estimatedMinutes: 90,
          priority: PlanPriority.high,
          notes: '完成主要页面、异常状态和可交付评审链接。',
          subtasks: const [
            CoursePlanSubtask(id: 'prototype-1', title: '梳理主流程'),
            CoursePlanSubtask(id: 'prototype-2', title: '补齐异常状态', position: 1),
            CoursePlanSubtask(id: 'prototype-3', title: '导出评审链接', position: 2),
          ],
        ),
        CoursePlan(
          id: 'plan-database',
          courseId: 'database',
          title: '提交索引优化实验',
          dueAt: now.add(const Duration(days: 4)),
          estimatedMinutes: 60,
          priority: PlanPriority.medium,
          subtasks: const [
            CoursePlanSubtask(id: 'database-1', title: '执行 Explain'),
            CoursePlanSubtask(id: 'database-2', title: '整理对比数据', position: 1),
          ],
        ),
      ],
      dayOverrides: const [],
    );
  }
}
