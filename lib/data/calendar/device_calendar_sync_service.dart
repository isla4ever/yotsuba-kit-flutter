import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/data/calendar/schedule_calendar_entry.dart';

const _calendarName = 'Yotsuba Schedule';
const _calendarIdKey = 'calendar.deviceCalendarId';
const _eventMarker = '[Yotsuba Schedule generated event]';

bool get supportsDirectCalendarSync {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

final deviceCalendarSyncServiceProvider = Provider((ref) {
  return DeviceCalendarSyncService(ref.watch(sharedPreferencesProvider));
});

enum DeviceCalendarSyncFailure { denied, restricted, unavailable, failed }

class DeviceCalendarSyncException implements Exception {
  const DeviceCalendarSyncException(this.failure, this.message);

  final DeviceCalendarSyncFailure failure;
  final String message;

  @override
  String toString() => message;
}

class DeviceCalendarSyncResult {
  const DeviceCalendarSyncResult({
    required this.created,
    required this.removed,
  });

  final int created;
  final int removed;
}

class DeviceCalendarSyncService {
  DeviceCalendarSyncService(this._preferences, {DeviceCalendar? plugin})
    : _plugin = plugin ?? DeviceCalendar.instance;

  final SharedPreferences? _preferences;
  final DeviceCalendar _plugin;

  Future<DeviceCalendarSyncResult> sync({
    required List<ScheduleCalendarEntry> entries,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (!supportsDirectCalendarSync) {
      throw const DeviceCalendarSyncException(
        DeviceCalendarSyncFailure.unavailable,
        '当前平台不支持直接写入系统日历',
      );
    }

    await _ensureFullAccess();
    try {
      final calendarId = await _resolveCalendarId();
      final oldEvents = await _plugin.listEvents(
        rangeStart,
        rangeEnd,
        calendarIds: [calendarId],
      );
      final generatedOldIds = oldEvents
          .where((event) => event.description?.contains(_eventMarker) ?? false)
          .map((event) => event.eventId)
          .toSet();

      final createdIds = <String>[];
      try {
        for (var index = 0; index < entries.length; index += 8) {
          final chunk = entries.skip(index).take(8);
          createdIds.addAll(
            await Future.wait(
              chunk.map((entry) => _createEvent(calendarId, entry)),
            ),
          );
        }
      } on Object {
        await Future.wait(
          createdIds.map(
            (id) => _plugin.deleteEvent(eventId: id).catchError((_) {}),
          ),
        );
        rethrow;
      }

      var removed = 0;
      for (final eventId in generatedOldIds) {
        try {
          await _plugin.deleteEvent(eventId: eventId);
          removed++;
        } on Object {
          // A successful new sync should remain usable even if an old event was
          // removed externally between listing and cleanup.
        }
      }
      return DeviceCalendarSyncResult(
        created: createdIds.length,
        removed: removed,
      );
    } on DeviceCalendarSyncException {
      rethrow;
    } on DeviceCalendarException catch (error) {
      throw _mapPluginException(error);
    } on Object catch (error) {
      throw DeviceCalendarSyncException(
        DeviceCalendarSyncFailure.failed,
        '日历同步失败：$error',
      );
    }
  }

  Future<void> openAppSettings() => _plugin.openAppSettings();

  Future<void> _ensureFullAccess() async {
    CalendarPermissionStatus status;
    try {
      status = await _plugin.hasPermissions();
      if (status != CalendarPermissionStatus.granted) {
        status = await _plugin.requestPermissions(
          level: CalendarAccessLevel.full,
        );
      }
    } on DeviceCalendarException catch (error) {
      throw _mapPluginException(error);
    }

    if (status == CalendarPermissionStatus.restricted) {
      throw const DeviceCalendarSyncException(
        DeviceCalendarSyncFailure.restricted,
        '系统限制了日历访问，请检查屏幕使用时间或设备管理策略',
      );
    }
    if (status != CalendarPermissionStatus.granted) {
      throw const DeviceCalendarSyncException(
        DeviceCalendarSyncFailure.denied,
        '需要允许完整日历权限才能更新整学期事件',
      );
    }
  }

  Future<String> _resolveCalendarId() async {
    final calendars = await _plugin.listCalendars();
    final storedId = _preferences?.getString(_calendarIdKey);
    final stored = calendars
        .where((calendar) => calendar.id == storedId && !calendar.readOnly)
        .firstOrNull;
    if (stored != null) return stored.id;

    final existing = calendars
        .where(
          (calendar) =>
              calendar.name == _calendarName &&
              !calendar.readOnly &&
              !calendar.hidden,
        )
        .firstOrNull;
    if (existing != null) {
      await _preferences?.setString(_calendarIdKey, existing.id);
      return existing.id;
    }

    final calendarId = await _plugin.createCalendar(
      name: _calendarName,
      colorHex: '#2C8B7F',
    );
    await _preferences?.setString(_calendarIdKey, calendarId);
    return calendarId;
  }

  Future<String> _createEvent(String calendarId, ScheduleCalendarEntry entry) {
    final description = [
      if (entry.description.isNotEmpty) entry.description,
      _eventMarker,
      '[YS_ID:${entry.id}]',
    ].join('\n');
    return _plugin.createEvent(
      calendarId: calendarId,
      title: entry.title,
      startDate: entry.start,
      endDate: entry.end,
      description: description,
      location: entry.location.isEmpty ? null : entry.location,
      reminders: entry.reminders,
    );
  }

  DeviceCalendarSyncException _mapPluginException(
    DeviceCalendarException error,
  ) {
    return switch (error.errorCode) {
      DeviceCalendarError.permissionDenied ||
      DeviceCalendarError.permissionsNotDeclared => DeviceCalendarSyncException(
        DeviceCalendarSyncFailure.denied,
        error.errorCode == DeviceCalendarError.permissionsNotDeclared
            ? '应用缺少系统日历权限声明'
            : '未获得系统日历权限',
      ),
      DeviceCalendarError.calendarUnavailable =>
        const DeviceCalendarSyncException(
          DeviceCalendarSyncFailure.unavailable,
          '当前设备没有可用的系统日历',
        ),
      _ => DeviceCalendarSyncException(
        DeviceCalendarSyncFailure.failed,
        '日历同步失败：${error.message}',
      ),
    };
  }
}
