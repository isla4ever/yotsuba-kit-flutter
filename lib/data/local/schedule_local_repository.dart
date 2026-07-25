import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:yotsuba_schedule/data/mock/mock_schedule_repository.dart';
import 'package:yotsuba_schedule/domain/models/schedule_data.dart';

const _scheduleDataKey = 'schedule.localData.v2';

class ScheduleLocalRepository {
  const ScheduleLocalRepository(this._preferences, this._fallback);

  final SharedPreferences? _preferences;
  final MockScheduleRepository _fallback;

  ScheduleData load() {
    final raw = _preferences?.getString(_scheduleDataKey);
    if (raw == null) return _fallback.load();
    try {
      return ScheduleData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return _fallback.load();
    }
  }

  Future<void> save(ScheduleData data) async {
    await _preferences?.setString(_scheduleDataKey, jsonEncode(data.toJson()));
  }

  Future<void> reset() async {
    await _preferences?.remove(_scheduleDataKey);
  }
}
