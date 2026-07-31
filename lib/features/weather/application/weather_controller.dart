import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/data/weather/weather_repository.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';

const _weatherCacheKey = 'weather.snapshot.v1';
const _weatherSourceKey = 'weather.source.v1';
const _weatherAutoRequestKey = 'weather.autoRequest.v1';
const _cacheTtl = Duration(minutes: 30);

enum WeatherStatus {
  idle,
  loading,
  ready,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
  error,
}

enum WeatherLocationPermission { denied, deniedForever, allowed }

@immutable
class WeatherCoordinates {
  const WeatherCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

abstract interface class WeatherLocationGateway {
  Future<bool> isServiceEnabled();

  Future<WeatherLocationPermission> checkPermission();

  Future<WeatherLocationPermission> requestPermission();

  Future<WeatherCoordinates?> currentCoordinates();

  Future<bool> openSettings({required bool locationService});
}

class GeolocatorWeatherLocationGateway implements WeatherLocationGateway {
  const GeolocatorWeatherLocationGateway();

  @override
  Future<bool> isServiceEnabled() async {
    if (kIsWeb) return true;
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<WeatherLocationPermission> checkPermission() async {
    if (kIsWeb) return WeatherLocationPermission.allowed;
    return _mapPermission(await Geolocator.checkPermission());
  }

  @override
  Future<WeatherLocationPermission> requestPermission() async {
    if (kIsWeb) return WeatherLocationPermission.allowed;
    return _mapPermission(await Geolocator.requestPermission());
  }

  @override
  Future<WeatherCoordinates?> currentCoordinates() async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } on TimeoutException {
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) return null;
    return WeatherCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<bool> openSettings({required bool locationService}) {
    if (kIsWeb) return Future.value(false);
    return locationService
        ? Geolocator.openLocationSettings()
        : Geolocator.openAppSettings();
  }
}

WeatherLocationPermission _mapPermission(LocationPermission permission) {
  return switch (permission) {
    LocationPermission.denied => WeatherLocationPermission.denied,
    LocationPermission.deniedForever => WeatherLocationPermission.deniedForever,
    _ => WeatherLocationPermission.allowed,
  };
}

class WeatherState {
  const WeatherState({
    this.status = WeatherStatus.idle,
    this.snapshot,
    this.message = '',
    this.campusFallback = false,
    this.demoMode = false,
  });

  final WeatherStatus status;
  final WeatherSnapshot? snapshot;
  final String message;
  final bool campusFallback;
  final bool demoMode;

  WeatherState copyWith({
    WeatherStatus? status,
    WeatherSnapshot? snapshot,
    String? message,
    bool? campusFallback,
    bool? demoMode,
  }) {
    return WeatherState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      message: message ?? this.message,
      campusFallback: campusFallback ?? this.campusFallback,
      demoMode: demoMode ?? this.demoMode,
    );
  }

  DailyWeather? weatherForDate(String dateKey) =>
      snapshot?.weatherForDate(dateKey);
}

final weatherRepositoryProvider = Provider((ref) => const WeatherRepository());

final weatherLocationGatewayProvider = Provider<WeatherLocationGateway>(
  (ref) => const GeolocatorWeatherLocationGateway(),
);

final weatherControllerProvider =
    NotifierProvider<WeatherController, WeatherState>(WeatherController.new);

class WeatherController extends Notifier<WeatherState> {
  @override
  WeatherState build() {
    final raw = ref
        .watch(sharedPreferencesProvider)
        ?.getString(_weatherCacheKey);
    if (raw == null) {
      return WeatherState(
        status: WeatherStatus.ready,
        snapshot: _demoWeatherSnapshot(),
        message: '分时天气演示',
        demoMode: true,
      );
    }
    try {
      final snapshot = WeatherSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return WeatherState(
        status: WeatherStatus.ready,
        snapshot: snapshot,
        campusFallback:
            ref
                .watch(sharedPreferencesProvider)
                ?.getString(_weatherSourceKey) ==
            'campus',
      );
    } on Object {
      return const WeatherState();
    }
  }

  Future<void> requestAutomatically() async {
    if (state.demoMode) return;
    final snapshot = state.snapshot;
    if (snapshot != null &&
        DateTime.now().difference(snapshot.fetchedAt) > _cacheTtl) {
      await _refresh(
        snapshot.latitude,
        snapshot.longitude,
        campusFallback: state.campusFallback,
      );
    }
  }

  Future<WeatherStatus> requestLocation() async {
    if (state.status == WeatherStatus.loading) return state.status;
    state = state.copyWith(status: WeatherStatus.loading, message: '正在匹配当前位置');
    try {
      final location = ref.read(weatherLocationGatewayProvider);
      if (!await location.isServiceEnabled()) {
        state = state.copyWith(
          status: WeatherStatus.serviceDisabled,
          message: '系统定位服务尚未开启',
        );
        return state.status;
      }
      var permission = await location.checkPermission();
      if (permission == WeatherLocationPermission.denied) {
        permission = await location.requestPermission();
      }
      if (permission == WeatherLocationPermission.deniedForever) {
        state = state.copyWith(
          status: WeatherStatus.deniedForever,
          message: '请在系统设置中允许定位',
        );
        return state.status;
      }
      if (permission == WeatherLocationPermission.denied) {
        state = state.copyWith(
          status: WeatherStatus.denied,
          message: '未获得定位权限，点击可以再次尝试',
        );
        return state.status;
      }
      final coordinates = await location.currentCoordinates();
      if (coordinates == null) {
        state = state.copyWith(
          status: WeatherStatus.error,
          message: '暂时无法取得位置，可使用学校附近天气',
        );
        return state.status;
      }
      await _refresh(
        coordinates.latitude,
        coordinates.longitude,
        campusFallback: false,
      );
      await ref
          .read(sharedPreferencesProvider)
          ?.setBool(_weatherAutoRequestKey, true);
      return state.status;
    } on PermissionDeniedException {
      state = state.copyWith(
        status: WeatherStatus.denied,
        message: kIsWeb ? '请在浏览器的网站权限中允许定位' : '未获得定位权限',
      );
      return state.status;
    } on LocationServiceDisabledException {
      state = state.copyWith(
        status: WeatherStatus.serviceDisabled,
        message: '系统定位服务尚未开启',
      );
      return state.status;
    } on UnsupportedError {
      state = state.copyWith(
        status: WeatherStatus.unavailable,
        message: '当前设备不支持定位天气',
      );
      return state.status;
    } on Object catch (error) {
      state = state.copyWith(
        status: WeatherStatus.error,
        message: kDebugMode ? '天气暂时不可用：$error' : '天气暂时不可用，可点击重试',
      );
      return state.status;
    }
  }

  Future<WeatherStatus> useCampusWeather() async {
    state = state.copyWith(
      status: WeatherStatus.loading,
      message: '正在获取学校附近天气',
    );
    await _refresh(34.60, 119.22, campusFallback: true);
    return state.status;
  }

  Future<bool> openPermissionSettings() async {
    return ref
        .read(weatherLocationGatewayProvider)
        .openSettings(
          locationService: state.status == WeatherStatus.serviceDisabled,
        );
  }

  Future<void> _refresh(
    double latitude,
    double longitude, {
    required bool campusFallback,
  }) async {
    try {
      final snapshot = await ref
          .read(weatherRepositoryProvider)
          .fetch(latitude: latitude, longitude: longitude);
      await ref
          .read(sharedPreferencesProvider)
          ?.setString(_weatherCacheKey, jsonEncode(snapshot.toJson()));
      await ref
          .read(sharedPreferencesProvider)
          ?.setString(_weatherSourceKey, campusFallback ? 'campus' : 'device');
      state = WeatherState(
        status: WeatherStatus.ready,
        snapshot: snapshot,
        campusFallback: campusFallback,
        demoMode: false,
      );
    } on Object catch (error) {
      if (kDebugMode) debugPrint('Weather refresh failed: $error');
      state = state.copyWith(
        status: WeatherStatus.error,
        message: kDebugMode ? '天气请求失败：$error' : '天气服务连接失败，请稍后重试',
      );
    }
  }
}

WeatherSnapshot _demoWeatherSnapshot() {
  final now = DateTime.now();
  final monday = DateTime(
    now.year,
    now.month,
    now.day - (now.weekday - DateTime.monday),
  );
  const dailyCodes = [0, 2, 3, 45, 51, 63, 65, 95, 71];
  const timeParts = <(int, int)>[
    (8, 0),
    (10, 0),
    (14, 30),
    (16, 20),
    (18, 10),
    (19, 30),
  ];
  const hourlyCodes = <List<int>>[
    [0, 2, 51, 71, 63, 3],
    [71, 0, 2, 45, 63, 95],
    [2, 63, 0, 71, 3, 45],
    [45, 0, 51, 95, 2, 63],
    [71, 3, 0, 65, 45, 2],
  ];
  return WeatherSnapshot(
    latitude: 34.60,
    longitude: 119.22,
    timezone: 'Asia/Shanghai',
    currentTemperature: 26,
    currentWeatherCode: 0,
    fetchedAt: now,
    daily: [
      for (var index = 0; index < dailyCodes.length; index++)
        DailyWeather(
          dateKey: _dateKey(monday.add(Duration(days: index))),
          weatherCode: dailyCodes[index],
          temperatureMax: 28 - index.toDouble(),
          temperatureMin: 20 - (index ~/ 2).toDouble(),
          precipitationProbability: switch (dailyCodes[index]) {
            51 => 42,
            63 => 68,
            65 => 86,
            95 => 78,
            71 => 54,
            _ => 12,
          },
        ),
    ],
    hourly: [
      for (var day = 0; day < dailyCodes.length; day++)
        for (var index = 0; index < timeParts.length; index++)
          HourlyWeather(
            time: DateTime(
              monday.year,
              monday.month,
              monday.day + day,
              timeParts[index].$1,
              timeParts[index].$2,
            ),
            weatherCode: hourlyCodes[day % hourlyCodes.length][index],
            temperature: 25 - day - (index ~/ 2).toDouble(),
          ),
    ],
  );
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
