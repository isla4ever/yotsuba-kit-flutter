import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';
import 'package:yotsuba_schedule/features/schedule/application/schedule_controller.dart';

void main() {
  test('persists day tasks, course plans and subtasks together', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final initial = container.read(scheduleControllerProvider);
    final controller = container.read(scheduleControllerProvider.notifier);

    controller.addDayTask(DateTime(2026, 7, 25), '验证离线保存');
    final plan = CoursePlan(
      id: 'test-plan',
      courseId: initial.courses.first.id,
      title: '完成迁移测试',
      estimatedMinutes: 45,
      subtasks: const [CoursePlanSubtask(id: 'subtask-1', title: '写测试')],
    );
    controller.saveCoursePlan(plan);
    controller.toggleCoursePlanSubtask('test-plan', 'subtask-1');
    await Future<void>.delayed(Duration.zero);

    final restored = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(restored.dispose);
    final state = restored.read(scheduleControllerProvider);
    expect(state.dayTasks.any((task) => task.title == '验证离线保存'), isTrue);
    final restoredPlan = state.coursePlans.firstWhere(
      (item) => item.id == 'test-plan',
    );
    expect(restoredPlan.subtasks.single.completed, isTrue);
  });

  test('auto scheduling avoids course time and writes a real slot', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final state = container.read(scheduleControllerProvider);
    final controller = container.read(scheduleControllerProvider.notifier);
    final plan = CoursePlan(
      id: 'auto-plan',
      courseId: state.courses.first.id,
      title: '自动安排测试',
      estimatedMinutes: 30,
      dueAt: DateTime.now().add(const Duration(days: 10)),
    );
    controller.saveCoursePlan(plan);
    final start = controller.autoScheduleCoursePlan('auto-plan');
    expect(start, isNotNull);
    final saved = container
        .read(scheduleControllerProvider)
        .coursePlans
        .firstWhere((item) => item.id == 'auto-plan');
    expect(saved.scheduledStart, start);
    expect(saved.scheduledEnd!.difference(start!).inMinutes, 30);
  });

  test('completed course work remains archived after restoring data', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    final state = container.read(scheduleControllerProvider);
    final controller = container.read(scheduleControllerProvider.notifier);
    final plan = CoursePlan(
      id: 'archived-plan',
      courseId: state.courses.first.id,
      title: '需要归档的课程作业',
      estimatedMinutes: 60,
    );

    controller.saveCoursePlan(plan);
    controller.setCoursePlanCompleted(plan.id, true);
    await Future<void>.delayed(Duration.zero);

    final restored = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(restored.dispose);
    final archived = restored
        .read(scheduleControllerProvider)
        .coursePlans
        .firstWhere((item) => item.id == plan.id);
    expect(archived.completed, isTrue);
    expect(archived.completedAt, isNotNull);

    restored
        .read(scheduleControllerProvider.notifier)
        .setCoursePlanCompleted(plan.id, false);
    final active = restored
        .read(scheduleControllerProvider)
        .coursePlans
        .firstWhere((item) => item.id == plan.id);
    expect(active.completed, isFalse);
    expect(active.completedAt, isNull);
  });
}
