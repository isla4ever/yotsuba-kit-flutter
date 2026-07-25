enum WeatherKind {
  sunny,
  cloudy,
  overcast,
  fog,
  drizzle,
  rain,
  storm,
  snow,
  neutral,
}

class WeatherPresentation {
  const WeatherPresentation(this.kind, this.label);

  final WeatherKind kind;
  final String label;
}

WeatherPresentation weatherPresentation(int code) {
  if (code == 0) return const WeatherPresentation(WeatherKind.sunny, '晴');
  if (code == 1 || code == 2) {
    return const WeatherPresentation(WeatherKind.cloudy, '多云');
  }
  if (code == 3) return const WeatherPresentation(WeatherKind.overcast, '阴');
  if (code == 45 || code == 48) {
    return const WeatherPresentation(WeatherKind.fog, '雾');
  }
  if ({51, 53, 55, 56, 57}.contains(code)) {
    return const WeatherPresentation(WeatherKind.drizzle, '小雨');
  }
  if ({61, 63, 80, 81}.contains(code)) {
    return WeatherPresentation(WeatherKind.rain, code == 61 ? '小雨' : '中雨');
  }
  if ({65, 66, 67, 82}.contains(code)) {
    return const WeatherPresentation(WeatherKind.rain, '大雨');
  }
  if ({71, 73, 75, 77, 85, 86}.contains(code)) {
    return const WeatherPresentation(WeatherKind.snow, '有雪');
  }
  if ({95, 96, 99}.contains(code)) {
    return const WeatherPresentation(WeatherKind.storm, '雷阵雨');
  }
  return const WeatherPresentation(WeatherKind.neutral, '天气');
}

class DailyWeather {
  const DailyWeather({
    required this.dateKey,
    required this.weatherCode,
    required this.temperatureMax,
    required this.temperatureMin,
    this.precipitationProbability,
  });

  final String dateKey;
  final int weatherCode;
  final double temperatureMax;
  final double temperatureMin;
  final int? precipitationProbability;

  Map<String, Object?> toJson() => {
    'dateKey': dateKey,
    'weatherCode': weatherCode,
    'temperatureMax': temperatureMax,
    'temperatureMin': temperatureMin,
    'precipitationProbability': precipitationProbability,
  };

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      dateKey: json['dateKey'] as String,
      weatherCode: json['weatherCode'] as int,
      temperatureMax: (json['temperatureMax'] as num).toDouble(),
      temperatureMin: (json['temperatureMin'] as num).toDouble(),
      precipitationProbability: json['precipitationProbability'] as int?,
    );
  }
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.currentTemperature,
    required this.currentWeatherCode,
    required this.fetchedAt,
    required this.daily,
  });

  final double latitude;
  final double longitude;
  final String timezone;
  final double currentTemperature;
  final int currentWeatherCode;
  final DateTime fetchedAt;
  final List<DailyWeather> daily;

  DailyWeather? weatherForDate(String dateKey) {
    for (final weather in daily) {
      if (weather.dateKey == dateKey) return weather;
    }
    return null;
  }

  Map<String, Object> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
    'currentTemperature': currentTemperature,
    'currentWeatherCode': currentWeatherCode,
    'fetchedAt': fetchedAt.toIso8601String(),
    'daily': daily.map((item) => item.toJson()).toList(),
  };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherSnapshot(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      currentTemperature: (json['currentTemperature'] as num).toDouble(),
      currentWeatherCode: json['currentWeatherCode'] as int,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      daily: (json['daily'] as List<dynamic>)
          .map((item) => DailyWeather.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
