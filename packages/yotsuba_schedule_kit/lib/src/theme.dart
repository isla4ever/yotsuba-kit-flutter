import 'package:flutter/material.dart';

import 'config.dart';

/// 主题令牌：与 npm 版 --ys-* 变量一一对应。
class YsScheduleTheme {
  const YsScheduleTheme({
    required this.canvas,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.accentSoft,
    required this.warning,
    required this.coursePalette,
  });

  final Color canvas;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color border;
  final Color borderStrong;
  final Color accent;
  final Color accentSoft;
  final Color warning;
  final List<Color> coursePalette;

  YsScheduleTheme copyWith({
    Color? canvas,
    Color? surface1,
    Color? surface2,
    Color? surface3,
    Color? text1,
    Color? text2,
    Color? text3,
    Color? border,
    Color? borderStrong,
    Color? accent,
    Color? accentSoft,
    Color? warning,
    List<Color>? coursePalette,
  }) =>
      YsScheduleTheme(
        canvas: canvas ?? this.canvas,
        surface1: surface1 ?? this.surface1,
        surface2: surface2 ?? this.surface2,
        surface3: surface3 ?? this.surface3,
        text1: text1 ?? this.text1,
        text2: text2 ?? this.text2,
        text3: text3 ?? this.text3,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        warning: warning ?? this.warning,
        coursePalette: coursePalette ?? this.coursePalette,
      );

  static const light = YsScheduleTheme(
    canvas: Color(0xFFF6F7F9),
    surface1: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEF1F5),
    surface3: Color(0xFFE3E8EE),
    text1: Color(0xFF1C232D),
    text2: Color(0xFF45505E),
    text3: Color(0xFF8A94A3),
    border: Color(0xFFDDE2E9),
    borderStrong: Color(0xFFC5CDD8),
    accent: Color(0xFF3D76DD),
    accentSoft: Color(0xFFE4EDFC),
    warning: Color(0xFFD97A12),
    coursePalette: _classic,
  );

  static const dark = YsScheduleTheme(
    canvas: Color(0xFF14171C),
    surface1: Color(0xFF1D2128),
    surface2: Color(0xFF242A33),
    surface3: Color(0xFF2C333E),
    text1: Color(0xFFEEF1F5),
    text2: Color(0xFFB8C0CC),
    text3: Color(0xFF7C8697),
    border: Color(0xFF333A45),
    borderStrong: Color(0xFF465060),
    accent: Color(0xFF6C9AEC),
    accentSoft: Color(0xFF22314D),
    warning: Color(0xFFE09A4A),
    coursePalette: _classicDark,
  );
}

const _classic = <Color>[
  Color(0xFFD1477A),
  Color(0xFF5A68D8),
  Color(0xFF0F9D8F),
  Color(0xFFC07A1B),
  Color(0xFF4B8BD4),
  Color(0xFFB0538F),
  Color(0xFF3F9D54),
  Color(0xFF8A63C9),
  Color(0xFFC25B3C),
  Color(0xFF2F8FA8),
];

const _classicDark = <Color>[
  Color(0xFFB34069),
  Color(0xFF5361B8),
  Color(0xFF118A7E),
  Color(0xFFA5691B),
  Color(0xFF40749F),
  Color(0xFF96477B),
  Color(0xFF398A4B),
  Color(0xFF7657AB),
  Color(0xFFA44F34),
  Color(0xFF2B7A8F),
];

List<Color> ysPaletteColors(YsPalette palette) => switch (palette) {
      YsPalette.classic => _classic,
      YsPalette.macaron => const [
          Color(0xFFE36B8D),
          Color(0xFF6D83DC),
          Color(0xFF35A995),
          Color(0xFFE49B45),
          Color(0xFF5A9ED6),
          Color(0xFFB66AB4),
        ],
      YsPalette.morandi => const [
          Color(0xFF8C6C79),
          Color(0xFF697990),
          Color(0xFF68877C),
          Color(0xFF9A7F61),
          Color(0xFF667F91),
          Color(0xFF7D718E),
        ],
      YsPalette.cyber => const [
          Color(0xFFDB3367),
          Color(0xFF5367E8),
          Color(0xFF078A84),
          Color(0xFFC46F14),
          Color(0xFF287DB8),
          Color(0xFF8B48B4),
        ],
      YsPalette.forest => const [
          Color(0xFF346B52),
          Color(0xFF647A47),
          Color(0xFF357879),
          Color(0xFF8A6D3B),
          Color(0xFF466A83),
          Color(0xFF6F5D76),
        ],
      YsPalette.sunset => const [
          Color(0xFFC85162),
          Color(0xFF8A5C9C),
          Color(0xFF4B7E8B),
          Color(0xFFC3773E),
          Color(0xFF5F6D9C),
          Color(0xFFA75473),
        ],
    };

/// 按课程名稳定分配调色板颜色（同名课永远同色）。
class YsCourseColorResolver {
  YsCourseColorResolver(this.theme);

  final YsScheduleTheme theme;
  final Map<String, Color> _assigned = {};

  Color resolve(String name, {int? explicit}) {
    if (explicit != null) {
      return Color(explicit);
    }
    return _assigned.putIfAbsent(
      name,
      () => theme.coursePalette[_assigned.length % theme.coursePalette.length],
    );
  }
}
