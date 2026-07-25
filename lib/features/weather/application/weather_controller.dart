import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yotsuba_schedule/core/settings/app_settings.dart';
import 'package:yotsuba_schedule/data/weather/weather_repository.dart';
import 'package:yotsuba_schedule/domain/models/weather.dart';

const _weatherCacheKey = 'weather.snapshot.v1';
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

  Future<WeatherStatus> requestLocation() async {
    if (state.status == WeatherStatus.loading) return state.status;
    state = state.copyWith(status: WeatherStatus.loading, message: '正在匹配当前位置');
    try {
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        state = state.copyWith(
          status: WeatherStatus.serviceDisabled,
          message: '系统定位服务尚未开启',
        );
        return state.status;
      }
      if (!kIsWeb) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          state = state.copyWith(
            status: WeatherStatus.deniedForever,
            message: '请在系统设置中允许定位',
          );
          return state.status;
        }
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            status: WeatherStatus.denied,
            message: '未获得定位权限，点击可以再次尝试',
          );
          return state.status;
        }
      }
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
      if (position == null) {
        state = state.copyWith(
          status: WeatherStatus.error,
          message: '暂时无法取得位置，可使用学校附近天气',
        );
        return state.status;
      }
      await _refresh(position.latitude, position.longitude);
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
    await _refresh(34.60, 119.22);
    return state.status;
  }

  Future<bool> openPermissionSettings() async {
    if (kIsWeb) return false;
    if (state.status == WeatherStatus.serviceDisabled) {
      return Geolocator.openLocationSettings();
    }
    return Geolocator.openAppSettings();
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
