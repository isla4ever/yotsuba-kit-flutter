import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';

const _todayGuideCompletedKey = 'onboarding.today.completed.v1';

class TodayOnboardingState {
  const TodayOnboardingState({
    required this.completed,
    this.active = false,
    this.requestId = 0,
  });

  final bool completed;
  final bool active;
  final int requestId;

  TodayOnboardingState copyWith({
    bool? completed,
    bool? active,
    int? requestId,
  }) {
    return TodayOnboardingState(
      completed: completed ?? this.completed,
      active: active ?? this.active,
      requestId: requestId ?? this.requestId,
    );
  }
}

final todayOnboardingProvider =
    NotifierProvider<TodayOnboardingController, TodayOnboardingState>(
      TodayOnboardingController.new,
    );

class TodayOnboardingController extends Notifier<TodayOnboardingState> {
  @override
  TodayOnboardingState build() {
    final completed =
        ref
            .watch(sharedPreferencesProvider)
            ?.getBool(_todayGuideCompletedKey) ??
        false;
    return TodayOnboardingState(completed: completed);
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
        ?.setBool(_todayGuideCompletedKey, true);
    state = state.copyWith(completed: true, active: false);
  }
}
