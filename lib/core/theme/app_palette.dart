import 'package:flutter/material.dart';

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

  static const light = AppPalette(
    canvas: Color(0xFFF2F5F4),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF5F7F6),
    surfaceRaised: Color(0xFFF8FAFC),
    text: Color(0xFF17201F),
    textSoft: Color(0xFF596662),
    textFaint: Color(0xFF87918E),
    border: Color(0xFFDCE4E1),
    borderStrong: Color(0xFFC7CFD8),
    todayAccent: Color(0xFF176B53),
    todayAccentSoft: Color(0xFFE2F1EC),
    scheduleAccent: Color(0xFF356EF5),
    scheduleAccentSoft: Color(0xFFE8EFFF),
    blue: Color(0xFF315FCE),
    blueSoft: Color(0xFFE8EEFC),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFC73645),
    track: Color(0xFFE5EBE8),
    shadow: Color(0x1420302A),
  );

  static const dark = AppPalette(
    canvas: Color(0xFF101513),
    surface: Color(0xFF171E1C),
    surfaceMuted: Color(0xFF202825),
    surfaceRaised: Color(0xFF20242A),
    text: Color(0xFFF1F6F4),
    textSoft: Color(0xFFB2BFBA),
    textFaint: Color(0xFF85928D),
    border: Color(0xFF303B37),
    borderStrong: Color(0xFF444C56),
    todayAccent: Color(0xFF62C7A2),
    todayAccentSoft: Color(0xFF19372E),
    scheduleAccent: Color(0xFF7AA2FF),
    scheduleAccentSoft: Color(0xFF202C48),
    blue: Color(0xFF8AA9FF),
    blueSoft: Color(0xFF202E4B),
    success: Color(0xFF63C181),
    warning: Color(0xFFF0AD56),
    danger: Color(0xFFFF7D89),
    track: Color(0xFF29332F),
    shadow: Color(0x47000000),
  );

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
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
