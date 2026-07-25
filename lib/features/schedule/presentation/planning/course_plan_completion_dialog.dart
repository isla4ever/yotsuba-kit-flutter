import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/domain/models/course_plan.dart';

Future<bool> confirmCoursePlanCompletion(
  BuildContext context,
  CoursePlan plan,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      title: const Text('确认完成课程作业？'),
      content: Text('“${plan.title}”完成后会归入已完成记录，并保留完成时间，之后仍可在课程计划中恢复。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('再检查一下'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('确认完成'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
