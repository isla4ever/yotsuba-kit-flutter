import 'package:flutter_test/flutter_test.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';

void main() {
  test('keeps rain intensity and thunderstorms distinct', () {
    expect(weatherPresentation(51).kind, WeatherKind.drizzle);
    expect(weatherPresentation(61).kind, WeatherKind.rain);
    expect(weatherPresentation(63).kind, WeatherKind.rain);
    expect(weatherPresentation(65).kind, WeatherKind.heavyRain);
    expect(weatherPresentation(82).kind, WeatherKind.heavyRain);
    expect(weatherPresentation(95).kind, WeatherKind.storm);
  });

  test('hourly weather survives cache serialization', () {
    final snapshot = WeatherSnapshot(
      latitude: 39.1,
      longitude: 117.2,
      timezone: 'Asia/Shanghai',
      currentTemperature: 24,
      currentWeatherCode: 1,
      fetchedAt: DateTime(2026, 7, 28, 8),
      daily: const [
        DailyWeather(
          dateKey: '2026-07-28',
          weatherCode: 1,
          temperatureMax: 29,
          temperatureMin: 22,
        ),
      ],
      hourly: [
        HourlyWeather(
          time: DateTime(2026, 7, 28, 15),
          weatherCode: 71,
          temperature: 2,
        ),
      ],
    );

    final restored = WeatherSnapshot.fromJson(snapshot.toJson());
    expect(restored.hourly.single.weatherCode, 71);
    final first = restored.weatherForDateTime(DateTime(2026, 7, 28, 14, 30));
    final second = restored.weatherForDateTime(DateTime(2026, 7, 28, 14, 30));
    expect(first?.temperatureMax, 2);
    expect(identical(first, second), isTrue);
  });
}
