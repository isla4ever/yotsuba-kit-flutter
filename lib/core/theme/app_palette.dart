import 'package:flutter/material.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.text,
    required this.textSoft,
    required this.textFaint,
    required this.border,
    required this.borderStrong,
    required this.todayAccent,
    required this.todayAccentSoft,
    required this.scheduleAccent,
    required this.scheduleAccentSoft,
    required this.blue,
    required this.blueSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.track,
    required this.shadow,
    required this.courseColors,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceRaised;
  final Color text;
  final Color textSoft;
  final Color textFaint;
  final Color border;
  final Color borderStrong;
  final Color todayAccent;
  final Color todayAccentSoft;
  final Color scheduleAccent;
  final Color scheduleAccentSoft;
  final Color blue;
  final Color blueSoft;
  final Color success;
  final Color warning;
  final Color danger;
  final Color track;
  final Color shadow;
  final List<Color> courseColors;

  static const light = AppPalette(
    canvas: Color(0xFFF3F5F8),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF5F7FA),
    surfaceRaised: Color(0xFFF8FAFC),
    text: Color(0xFF18202D),
    textSoft: Color(0xFF5D6878),
    textFaint: Color(0xFF8993A2),
    border: Color(0xFFDDE2EA),
    borderStrong: Color(0xFFC7CFD8),
    todayAccent: Color(0xFF356EF5),
    todayAccentSoft: Color(0xFFE8EFFF),
    scheduleAccent: Color(0xFF356EF5),
    scheduleAccentSoft: Color(0xFFE8EFFF),
    blue: Color(0xFF315FCE),
    blueSoft: Color(0xFFE8EEFC),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFC73645),
    track: Color(0xFFE7EAF0),
    shadow: Color(0x14263246),
    courseColors: _classicCourseColors,
  );

  static const dark = AppPalette(
    canvas: Color(0xFF101319),
    surface: Color(0xFF181C24),
    surfaceMuted: Color(0xFF202631),
    surfaceRaised: Color(0xFF20242A),
    text: Color(0xFFF2F5FA),
    textSoft: Color(0xFFB5BECC),
    textFaint: Color(0xFF8791A0),
    border: Color(0xFF303744),
    borderStrong: Color(0xFF444C56),
    todayAccent: Color(0xFF7AA2FF),
    todayAccentSoft: Color(0xFF202C48),
    scheduleAccent: Color(0xFF7AA2FF),
    scheduleAccentSoft: Color(0xFF202C48),
    blue: Color(0xFF8AA9FF),
    blueSoft: Color(0xFF202E4B),
    success: Color(0xFF63C181),
    warning: Color(0xFFF0AD56),
    danger: Color(0xFFFF7D89),
    track: Color(0xFF29313E),
    shadow: Color(0x47000000),
    courseColors: _classicCourseColors,
  );

  static AppPalette resolve(YsPalette name, Brightness brightness) {
    final base = brightness == Brightness.dark ? dark : light;
    final isDark = brightness == Brightness.dark;
    return switch (name) {
      YsPalette.classic => base.copyWith(courseColors: ysPaletteColors(name)),
      YsPalette.macaron => base.copyWith(
        todayAccent: const Color(0xFFE7657C),
        todayAccentSoft: isDark
            ? const Color(0xFF43252F)
            : const Color(0xFFFFE8ED),
        scheduleAccent: const Color(0xFF1F9A83),
        scheduleAccentSoft: isDark
            ? const Color(0xFF193B36)
            : const Color(0xFFDFF5EF),
        blue: const Color(0xFF5277C8),
        blueSoft: isDark ? const Color(0xFF252F49) : const Color(0xFFE7EDFA),
        courseColors: ysPaletteColors(name),
      ),
      YsPalette.morandi => base.copyWith(
        todayAccent: const Color(0xFF687D91),
        todayAccentSoft: isDark
            ? const Color(0xFF29333E)
            : const Color(0xFFE5EBEF),
        scheduleAccent: const Color(0xFF6E887A),
        scheduleAccentSoft: isDark
            ? const Color(0xFF29382F)
            : const Color(0xFFE4ECE7),
        warning: const Color(0xFF9A6C43),
        courseColors: ysPaletteColors(name),
      ),
      YsPalette.cyber => base.copyWith(
        todayAccent: const Color(0xFF008FA3),
        todayAccentSoft: isDark
            ? const Color(0xFF14363D)
            : const Color(0xFFDDF5F7),
        scheduleAccent: const Color(0xFFB4458D),
        scheduleAccentSoft: isDark
            ? const Color(0xFF3D2035)
            : const Color(0xFFF8E3F0),
        blue: const Color(0xFF2867C7),
        courseColors: ysPaletteColors(name),
      ),
      YsPalette.forest => base.copyWith(
        todayAccent: const Color(0xFF26725A),
        todayAccentSoft: isDark
            ? const Color(0xFF1B362D)
            : const Color(0xFFDDEFE8),
        scheduleAccent: const Color(0xFF3A7654),
        scheduleAccentSoft: isDark
            ? const Color(0xFF21382A)
            : const Color(0xFFE2F0E6),
        warning: const Color(0xFFC17A27),
        courseColors: ysPaletteColors(name),
      ),
      YsPalette.sunset => base.copyWith(
        todayAccent: const Color(0xFFD45B55),
        todayAccentSoft: isDark
            ? const Color(0xFF452723)
            : const Color(0xFFFFE8E4),
        scheduleAccent: const Color(0xFF397BA6),
        scheduleAccentSoft: isDark
            ? const Color(0xFF203545)
            : const Color(0xFFE3F0F7),
        warning: const Color(0xFFD4862D),
        courseColors: ysPaletteColors(name),
      ),
    };
  }

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceRaised,
    Color? text,
    Color? textSoft,
    Color? textFaint,
    Color? border,
    Color? borderStrong,
    Color? todayAccent,
    Color? todayAccentSoft,
    Color? scheduleAccent,
    Color? scheduleAccentSoft,
    Color? blue,
    Color? blueSoft,
    Color? success,
    Color? warning,
    Color? danger,
    Color? track,
    Color? shadow,
    List<Color>? courseColors,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      text: text ?? this.text,
      textSoft: textSoft ?? this.textSoft,
      textFaint: textFaint ?? this.textFaint,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      todayAccent: todayAccent ?? this.todayAccent,
      todayAccentSoft: todayAccentSoft ?? this.todayAccentSoft,
      scheduleAccent: scheduleAccent ?? this.scheduleAccent,
      scheduleAccentSoft: scheduleAccentSoft ?? this.scheduleAccentSoft,
      blue: blue ?? this.blue,
      blueSoft: blueSoft ?? this.blueSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      track: track ?? this.track,
      shadow: shadow ?? this.shadow,
      courseColors: courseColors ?? this.courseColors,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSoft: Color.lerp(textSoft, other.textSoft, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      todayAccent: Color.lerp(todayAccent, other.todayAccent, t)!,
      todayAccentSoft: Color.lerp(todayAccentSoft, other.todayAccentSoft, t)!,
      scheduleAccent: Color.lerp(scheduleAccent, other.scheduleAccent, t)!,
      scheduleAccentSoft: Color.lerp(
        scheduleAccentSoft,
        other.scheduleAccentSoft,
        t,
      )!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueSoft: Color.lerp(blueSoft, other.blueSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      track: Color.lerp(track, other.track, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      courseColors: t < 0.5 ? courseColors : other.courseColors,
    );
  }
}

const _classicCourseColors = <Color>[
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

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
