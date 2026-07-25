import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';

const _scheduleGuideCompletedKey = 'onboarding.schedule.completed.v1';

class ScheduleOnboardingState {
  const ScheduleOnboardingState({
    required this.completed,
    this.active = false,
    this.requestId = 0,
  });

  final bool completed;
  final bool active;
  final int requestId;

  ScheduleOnboardingState copyWith({
    bool? completed,
    bool? active,
    int? requestId,
  }) {
    return ScheduleOnboardingState(
      completed: completed ?? this.completed,
      active: active ?? this.active,
      requestId: requestId ?? this.requestId,
    );
  }
}

final scheduleOnboardingProvider =
    NotifierProvider<ScheduleOnboardingController, ScheduleOnboardingState>(
      ScheduleOnboardingController.new,
    );

class ScheduleOnboardingController extends Notifier<ScheduleOnboardingState> {
  @override
  ScheduleOnboardingState build() {
    final completed =
        ref
            .watch(sharedPreferencesProvider)
            ?.getBool(_scheduleGuideCompletedKey) ??
        false;
    return ScheduleOnboardingState(completed: completed);
  }

  void startIfNeeded() {
    if (!state.completed && !state.active) {
      state = state.copyWith(active: true, requestId: state.requestId + 1);
    }
  }

  void replay() {
    state = state.copyWith(active: true, requestId: state.requestId + 1);
  }

  Future<void> finish() async {
    await ref
        .read(sharedPreferencesProvider)
        ?.setBool(_scheduleGuideCompletedKey, true);
    state = state.copyWith(completed: true, active: false);
  }
}
