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
}
