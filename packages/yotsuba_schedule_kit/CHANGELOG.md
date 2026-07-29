# Changelog

## 0.7.1

- Prevented inactive leaving overlap cards from showing through while a new active course animates into the same timetable slot.
- Added package and full-app widget regression tests for the affected wave-transition frame.

## 0.7.0

- Reworked course weather into localized micro-motion: sun halo, drifting cloud edge, glass rain traces, storm refraction, frost points, and feathered fog.
- Preserved the original course color as the card foundation and made course-card weather glyphs opt-in with `weatherCardGlyph`.
- Replaced full-screen precipitation and lightning flashes with slow blurred weather ambience and smoother state transitions.
- Added hourly weather points and nearest-course-time matching so courses on the same day can use different weather and temperatures.
- Kept inactive courses desaturated, restored weekend weather layers, and constrained compact cards and long course text without changing timetable presentation.
- Added distinct `1x1`, `1x2`, `2x1`, and `2x2` Today weather layouts, including hourly summaries and a large temperature trend.

## 0.6.0

- Added structured `materialDetails`, `books`, and `tasks` while retaining legacy string `materials`.
- Enabled weather-aware course card glyphs/tints, weekday forecasts, weather detail heroes, and scenes by default.
- Added distinct animated glyphs, scenes, and course-card layers for clear, cloudy, overcast, fog, drizzle, rain, heavy rain, storm, and snow.
- Made real-time weather the default course-card presentation; explicit shimmer, glow, aurora, and breathe effects automatically replace the weather layer while preserving the weather glyph.
- Added configurable empty-value text while preserving detail labels for missing information.
- Added animated overlap-course detail transitions within the same adaptive sheet.
- Reworked Today for mobile whole-card dragging, four-corner resizing, course tasks, structured carry lists, and custom builders.

## 0.5.0

- Added high-level `YsSchedule` with configurable Header, built-in week picker, course detail, backgrounds, and host actions.
- Added `slide`, `fade`, `cube`, `drop`, and `zoom` transitions alongside `wave` and `none`; all animated presets retain and fade the leaving week.
- Added compact, standard, and full course-detail layouts with weather-aware Hero presentation.
- Added per-sheet default placement and in-sheet Header controls for bottom, center, and right layouts.
- Added weather snapshot/provider contracts, animated glyphs, date-header forecasts, and weather scenes.
- Added schedule density, six color palettes, five card effects, and reduced-motion handling.
- Added `YsToday` with six built-in modules, custom builders, long-press arrangement, reordering, and three widget sizes.
- Expanded courses with materials, notes, and host metadata.
- Rebuilt the example as a complete Schedule / Today / Settings showcase using only package APIs.

## 0.1.0

- Initial `YsWeekTimetable`, academic-term engine, wave transition, theme tokens, and overlap callbacks.
