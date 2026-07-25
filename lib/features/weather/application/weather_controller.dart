import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/data/weather/weather_repository.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';

const _weatherCacheKey = 'weather.snapshot.v1';
const _weatherAutoRequestKey = 'weather.autoRequest.v1';
const _cacheTtl = Duration(minutes: 30);

enum WeatherStatus { idle, loading, ready, denied, unavailable, error }

class WeatherState {
  const WeatherState({
    this.status = WeatherStatus.idle,
    this.snapshot,
    this.message = '',
  });

  final WeatherStatus status;
  final WeatherSnapshot? snapshot;
  final String message;

  WeatherState copyWith({
    WeatherStatus? status,
    WeatherSnapshot? snapshot,
    String? message,
  }) {
    return WeatherState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      message: message ?? this.message,
    );
  }

  DailyWeather? weatherForDate(String dateKey) =>
      snapshot?.weatherForDate(dateKey);
}

final weatherRepositoryProvider = Provider((ref) => const WeatherRepository());

final weatherControllerProvider =
    NotifierProvider<WeatherController, WeatherState>(WeatherController.new);

class WeatherController extends Notifier<WeatherState> {
  @override
  WeatherState build() {
    final raw = ref
        .watch(sharedPreferencesProvider)
        ?.getString(_weatherCacheKey);
    if (raw == null) return const WeatherState();
    try {
      final snapshot = WeatherSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return WeatherState(status: WeatherStatus.ready, snapshot: snapshot);
    } on Object {
      return const WeatherState();
    }
  }

  Future<void> requestAutomatically() async {
    final preferences = ref.read(sharedPreferencesProvider);
    if (preferences?.getBool(_weatherAutoRequestKey) == true) {
      final snapshot = state.snapshot;
      if (snapshot != null &&
          DateTime.now().difference(snapshot.fetchedAt) > _cacheTtl) {
        await _refresh(snapshot.latitude, snapshot.longitude);
      }
      return;
    }
    await preferences?.setBool(_weatherAutoRequestKey, true);
    await requestLocation();
  }

  Future<void> requestLocation() async {
    if (state.status == WeatherStatus.loading) return;
    state = state.copyWith(status: WeatherStatus.loading, message: '正在匹配当前位置');
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          status: WeatherStatus.denied,
          message: permission == LocationPermission.deniedForever
              ? '定位权限已关闭，请在系统设置中开启'
              : '未获得定位权限',
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      await _refresh(position.latitude, position.longitude);
    } on UnsupportedError {
      state = state.copyWith(
        status: WeatherStatus.unavailable,
        message: '当前设备不支持定位天气',
      );
    } on Object {
      state = state.copyWith(
        status: WeatherStatus.error,
        message: '天气暂时不可用，点击可重试',
      );
    }
  }

  Future<void> _refresh(double latitude, double longitude) async {
    try {
      final snapshot = await ref
          .read(weatherRepositoryProvider)
          .fetch(latitude: latitude, longitude: longitude);
      await ref
          .read(sharedPreferencesProvider)
          ?.setString(_weatherCacheKey, jsonEncode(snapshot.toJson()));
      state = WeatherState(status: WeatherStatus.ready, snapshot: snapshot);
    } on Object {
      state = state.copyWith(
        status: WeatherStatus.error,
        message: '天气暂时不可用，点击可重试',
      );
    }
  }
}
