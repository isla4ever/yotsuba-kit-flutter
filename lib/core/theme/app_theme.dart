import 'package:flutter/material.dart';
import 'package:yotsuba_schedule/core/theme/app_palette.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light([YsPalette paletteName = YsPalette.classic]) {
    return _build(
      Brightness.light,
      AppPalette.resolve(paletteName, Brightness.light),
    );
  }

  static ThemeData dark([YsPalette paletteName = YsPalette.classic]) {
    return _build(
      Brightness.dark,
      AppPalette.resolve(paletteName, Brightness.dark),
    );
  }

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.todayAccent,
      onPrimary: Colors.white,
      primaryContainer: palette.todayAccentSoft,
      onPrimaryContainer: palette.text,
      secondary: palette.scheduleAccent,
      onSecondary: Colors.white,
      secondaryContainer: palette.scheduleAccentSoft,
      onSecondaryContainer: palette.text,
      error: palette.danger,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.text,
      outline: palette.borderStrong,
      outlineVariant: palette.border,
      surfaceContainerHighest: palette.surfaceMuted,
      onSurfaceVariant: palette.textSoft,
    );
    final baseTypography = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final textTheme = baseTypography.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
      fontFamily: 'NotoSansSC',
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      fontFamily: 'NotoSansSC',
      extensions: [palette],
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 60,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: palette.borderStrong,
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
