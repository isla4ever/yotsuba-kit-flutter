import 'package:flutter/material.dart';

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
    coursePalette: [
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
    ],
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
    coursePalette: [
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
    ],
  );
}

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
