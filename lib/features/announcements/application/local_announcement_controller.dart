import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/domain/models/local_announcement.dart';

const _announcementDataKey = 'announcements.local.v1';
const _announcementMutedKey = 'announcements.muted.v1';

class LocalAnnouncementState {
  const LocalAnnouncementState({
    this.items = const [],
    this.mutedIds = const {},
  });

  final List<LocalAnnouncement> items;
  final Set<String> mutedIds;

  LocalAnnouncement? get latestUnmuted {
    final published =
        items
            .where((item) => item.published && !mutedIds.contains(item.id))
            .toList()
          ..sort((a, b) => b.publishedAt!.compareTo(a.publishedAt!));
    return published.isEmpty ? null : published.first;
  }

  LocalAnnouncementState copyWith({
    List<LocalAnnouncement>? items,
    Set<String>? mutedIds,
  }) => LocalAnnouncementState(
    items: items ?? this.items,
    mutedIds: mutedIds ?? this.mutedIds,
  );
}

final localAnnouncementProvider =
    NotifierProvider<LocalAnnouncementController, LocalAnnouncementState>(
      LocalAnnouncementController.new,
    );

class LocalAnnouncementController extends Notifier<LocalAnnouncementState> {
  @override
  LocalAnnouncementState build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    final raw = preferences?.getString(_announcementDataKey);
    final muted = preferences?.getStringList(_announcementMutedKey) ?? const [];
    if (raw == null) {
      return LocalAnnouncementState(mutedIds: muted.toSet());
    }
    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return LocalAnnouncementState(
        items: values
            .map(
              (item) =>
                  LocalAnnouncement.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        mutedIds: muted.toSet(),
      );
    } on Object {
      return LocalAnnouncementState(mutedIds: muted.toSet());
    }
  }

  void save({
    String? id,
    required String title,
    required String content,
    bool publish = false,
  }) {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty || cleanContent.isEmpty) return;
    final items = [...state.items];
    final index = id == null ? -1 : items.indexWhere((item) => item.id == id);
    if (index == -1) {
      final now = DateTime.now();
      items.add(
        LocalAnnouncement(
          id: 'notice-${now.microsecondsSinceEpoch}',
          title: cleanTitle,
          content: cleanContent,
          createdAt: now,
          publishedAt: publish ? now : null,
        ),
      );
    } else {
      final current = items[index];
      items[index] = current.copyWith(
        title: cleanTitle,
        content: cleanContent,
        publishedAt: publish && !current.published ? DateTime.now() : null,
        clearPublishedAt: !publish,
      );
    }
    state = state.copyWith(items: items);
    _persist();
  }

  void setPublished(String id, bool value) {
    final items = state.items.map((item) {
      if (item.id != id) return item;
      return value
          ? item.copyWith(publishedAt: DateTime.now())
          : item.copyWith(clearPublishedAt: true);
    }).toList();
    final muted = {...state.mutedIds}..remove(id);
    state = state.copyWith(items: items, mutedIds: muted);
    _persist();
  }

  void delete(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
      mutedIds: {...state.mutedIds}..remove(id),
    );
    _persist();
  }

  void mute(String id) {
    state = state.copyWith(mutedIds: {...state.mutedIds, id});
    _persist();
  }

  void _persist() {
    final preferences = ref.read(sharedPreferencesProvider);
    preferences?.setString(
      _announcementDataKey,
      jsonEncode(state.items.map((item) => item.toJson()).toList()),
    );
    preferences?.setStringList(_announcementMutedKey, state.mutedIds.toList());
  }
}
