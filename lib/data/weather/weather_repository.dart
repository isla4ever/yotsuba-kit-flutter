import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yotsuba_schedule/domain/models/weather.dart';

class WeatherRepository {
  const WeatherRepository({this.httpClient});

  final http.Client? httpClient;

  Future<WeatherSnapshot> fetch({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toStringAsFixed(2),
      'longitude': longitude.toStringAsFixed(2),
      'current': 'temperature_2m,weather_code',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'forecast_days': '16',
      'timezone': 'auto',
    });
    final requestClient = httpClient ?? http.Client();
    try {
      final response = await requestClient
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StateError('Weather request failed: ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>;
      final dates = daily['time'] as List<dynamic>;
      final codes = daily['weather_code'] as List<dynamic>;
      final highs = daily['temperature_2m_max'] as List<dynamic>;
      final lows = daily['temperature_2m_min'] as List<dynamic>;
      final precipitation =
          daily['precipitation_probability_max'] as List<dynamic>?;
      return WeatherSnapshot(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezone: json['timezone'] as String,
        currentTemperature:
            (current['temperature_2m'] as num?)?.toDouble() ?? 0,
        currentWeatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
        fetchedAt: DateTime.now(),
        daily: List.generate(dates.length, (index) {
          return DailyWeather(
            dateKey: dates[index] as String,
            weatherCode: (codes[index] as num?)?.toInt() ?? 0,
            temperatureMax: (highs[index] as num?)?.toDouble() ?? 0,
            temperatureMin: (lows[index] as num?)?.toDouble() ?? 0,
            precipitationProbability: (precipitation?[index] as num?)?.toInt(),
          );
        }),
      );
    } finally {
      if (httpClient == null) requestClient.close();
    }
  }
}
