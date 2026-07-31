import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';

const _todayLayoutKey = 'today.dashboard.layout.v4';
const _legacyTodayLayoutKeys = [
  'today.dashboard.layout.v3',
  'today.dashboard.layout.v2',
  'today.dashboard.layout.v1',
];

enum TodayTileId {
  command,
  weather,
  timeline,
  readiness,
  tasks,
  courseWork,
  weekGlance,
  studyLoad,
  materials,
}

enum TodayTileSize {
  oneByOne(1, 1, '1x1'),
  oneByTwo(1, 2, '1x2'),
  twoByOne(2, 1, '2x1'),
  twoByTwo(2, 2, '2x2');

  const TodayTileSize(this.columns, this.rows, this.label);

  final int columns;
  final int rows;
  final String label;
}

class TodayTileConfig {
  const TodayTileConfig({
    required this.id,
    required this.size,
    this.visible = true,
  });

  final TodayTileId id;
  final TodayTileSize size;
  final bool visible;

  TodayTileConfig copyWith({TodayTileSize? size, bool? visible}) {
    return TodayTileConfig(
      id: id,
      size: size ?? this.size,
      visible: visible ?? this.visible,
    );
  }

  Map<String, Object> toJson() => {
    'id': id.name,
    'size': size.name,
    'visible': visible,
  };

  static TodayTileConfig? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = TodayTileId.values
        .where((item) => item.name == value['id'])
        .firstOrNull;
    final size = value['size'] == 'twoByFour'
        ? TodayTileSize.twoByTwo
        : TodayTileSize.values
              .where((item) => item.name == value['size'])
              .firstOrNull;
    if (id == null || size == null) return null;
    return TodayTileConfig(
      id: id,
      size: size,
      visible: value['visible'] != false,
    );
  }
}

const defaultTodayLayout = <TodayTileConfig>[
  TodayTileConfig(id: TodayTileId.command, size: TodayTileSize.twoByOne),
  TodayTileConfig(id: TodayTileId.weather, size: TodayTileSize.twoByTwo),
  TodayTileConfig(id: TodayTileId.timeline, size: TodayTileSize.twoByOne),
  TodayTileConfig(id: TodayTileId.readiness, size: TodayTileSize.oneByOne),
  TodayTileConfig(id: TodayTileId.courseWork, size: TodayTileSize.oneByOne),
  TodayTileConfig(id: TodayTileId.tasks, size: TodayTileSize.oneByOne),
  TodayTileConfig(id: TodayTileId.weekGlance, size: TodayTileSize.oneByOne),
  TodayTileConfig(id: TodayTileId.studyLoad, size: TodayTileSize.twoByOne),
  TodayTileConfig(
    id: TodayTileId.materials,
    size: TodayTileSize.twoByOne,
    visible: false,
  ),
];

final todayLayoutProvider =
    NotifierProvider<TodayLayoutController, List<TodayTileConfig>>(
      TodayLayoutController.new,
    );

class TodayLayoutController extends Notifier<List<TodayTileConfig>> {
  @override
  List<TodayTileConfig> build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    final current = _decodeLayout(preferences?.getString(_todayLayoutKey));
    if (current.isNotEmpty) return _completeLayout(current);

    var legacy = const <TodayTileConfig>[];
    for (final key in _legacyTodayLayoutKeys) {
      legacy = _decodeLayout(preferences?.getString(key));
      if (legacy.isNotEmpty) break;
    }
    final migrated = legacy.isEmpty
        ? defaultTodayLayout
        : _completeLayout(legacy);
    preferences?.setString(
      _todayLayoutKey,
      jsonEncode(migrated.map((item) => item.toJson()).toList()),
    );
    return migrated;
  }

  List<TodayTileConfig> _decodeLayout(String? raw) {
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(TodayTileConfig.fromJson)
          .whereType<TodayTileConfig>()
          .toList();
    } on Object {
      return const [];
    }
  }

  List<TodayTileConfig> _completeLayout(List<TodayTileConfig> stored) {
    final ids = stored.map((item) => item.id).toSet();
    return [
      ...stored,
      for (final item in defaultTodayLayout)
        if (!ids.contains(item.id)) item,
    ];
  }

  void moveToVisibleIndex(TodayTileId moving, int visibleIndex) {
    final visible = state.where((item) => item.visible).toList();
    final sourceIndex = visible.indexWhere((item) => item.id == moving);
    if (sourceIndex < 0) return;
    final item = visible.removeAt(sourceIndex);
    visible.insert(visibleIndex.clamp(0, visible.length), item);
    var cursor = 0;
    _save([
      for (final entry in state)
        if (entry.visible) visible[cursor++] else entry,
    ]);
  }

  void setSize(TodayTileId id, TodayTileSize size) {
    _save([
      for (final item in state)
        if (item.id == id) item.copyWith(size: size) else item,
    ]);
  }

  void setVisible(TodayTileId id, bool visible) {
    _save([
      for (final item in state)
        if (item.id == id) item.copyWith(visible: visible) else item,
    ]);
  }

  void reset() => _save(defaultTodayLayout);

  void _save(List<TodayTileConfig> next) {
    state = List.unmodifiable(next);
    ref
        .read(sharedPreferencesProvider)
        ?.setString(
          _todayLayoutKey,
          jsonEncode(next.map((item) => item.toJson()).toList()),
        );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
