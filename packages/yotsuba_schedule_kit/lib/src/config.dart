import 'package:flutter/material.dart';

enum YsTransition { wave, slide, fade, cube, drop, zoom, none }

enum YsHeaderStyle { compact, standard, expanded, none }

enum YsScheduleDensity { minimal, normal, rich }

enum YsPalette { classic, macaron, morandi, cyber, forest, sunset }

enum YsCardEffect { none, shimmer, glow, aurora, breathe }

enum YsDetailLayout { compact, standard, full }

enum YsDetailHero { courseColor, weather, plain }

enum YsDetailField {
  time,
  weeks,
  location,
  teacher,
  weather,
  note,
  materials,
  books,
  tasks,
}

enum YsDetailAction { share, edit, remove }

class YsCourseDetailConfig {
  const YsCourseDetailConfig({
    this.layout = YsDetailLayout.standard,
    this.hero = YsDetailHero.weather,
    this.fields,
    this.actions = const [
      YsDetailAction.share,
      YsDetailAction.edit,
      YsDetailAction.remove,
    ],
    this.adjustable = true,
    this.emptyText = '暂无信息',
    this.emptyTexts = const {},
  });

  final YsDetailLayout layout;
  final YsDetailHero hero;
  final List<YsDetailField>? fields;
  final List<YsDetailAction> actions;
  final bool adjustable;
  final String emptyText;
  final Map<YsDetailField, String> emptyTexts;

  YsCourseDetailConfig copyWith({
    YsDetailLayout? layout,
    YsDetailHero? hero,
    List<YsDetailField>? fields,
    List<YsDetailAction>? actions,
    bool? adjustable,
    String? emptyText,
    Map<YsDetailField, String>? emptyTexts,
  }) =>
      YsCourseDetailConfig(
        layout: layout ?? this.layout,
        hero: hero ?? this.hero,
        fields: fields ?? this.fields,
        actions: actions ?? this.actions,
        adjustable: adjustable ?? this.adjustable,
        emptyText: emptyText ?? this.emptyText,
        emptyTexts: emptyTexts ?? this.emptyTexts,
      );
}

enum YsSheetPlacement { bottom, center, right }

enum YsSheetKind {
  weekPicker,
  courseDetail,
  courseForm,
  dayPlanner,
  background,
  settings,
  custom,
}

class YsSheetConfig {
  const YsSheetConfig({
    this.placement = YsSheetPlacement.bottom,
    this.placements = const {},
    this.glass = true,
    this.adjustable = true,
    this.contained = false,
  });

  final YsSheetPlacement placement;
  final Map<YsSheetKind, YsSheetPlacement> placements;
  final bool glass;
  final bool adjustable;

  /// 使用最近的 Navigator，而不是强制根 Navigator。
  final bool contained;

  YsSheetPlacement placementFor(YsSheetKind kind) =>
      placements[kind] ?? placement;

  YsSheetConfig copyWith({
    YsSheetPlacement? placement,
    Map<YsSheetKind, YsSheetPlacement>? placements,
    bool? glass,
    bool? adjustable,
    bool? contained,
  }) =>
      YsSheetConfig(
        placement: placement ?? this.placement,
        placements: placements ?? this.placements,
        glass: glass ?? this.glass,
        adjustable: adjustable ?? this.adjustable,
        contained: contained ?? this.contained,
      );
}

class YsScheduleBackground {
  const YsScheduleBackground({
    this.image,
    this.opacity = 0.24,
    this.blur = 0,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final ImageProvider? image;
  final double opacity;
  final double blur;
  final BoxFit fit;
  final Alignment alignment;
}
