import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yotsuba_schedule/domain/models/academic_calendar.dart';

class ChinaHolidayRepository {
  const ChinaHolidayRepository([this._client]);

  final http.Client? _client;

  static const _sources = [
    'https://cdn.jsdelivr.net/gh/NateScarlet/holiday-cn@master',
    'https://raw.githubusercontent.com/NateScarlet/holiday-cn/master',
  ];

  Future<List<AcademicDayOverride>> fetchYears(Iterable<int> years) async {
    final uniqueYears = years.toSet().toList()..sort();
    final results = <AcademicDayOverride>[];
    for (final year in uniqueYears) {
      results.addAll(await _fetchYear(year));
    }
    return results;
  }

  Future<List<AcademicDayOverride>> _fetchYear(int year) async {
    Object? lastError;
    for (final source in _sources) {
      final client = _client ?? http.Client();
      try {
        final response = await client
            .get(Uri.parse('$source/$year.json'))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) {
          throw StateError('Holiday request failed: ${response.statusCode}');
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final days = json['days'] as List<dynamic>? ?? const [];
        return days.map((item) {
          final value = item as Map<String, dynamic>;
          final off = value['isOffDay'] as bool? ?? true;
          return AcademicDayOverride(
            dateKey: value['date'] as String,
            kind: off ? AcademicDayKind.holiday : AcademicDayKind.makeUp,
            name: value['name'] as String? ?? (off ? '法定节假日' : '调休补班'),
            isManual: false,
          );
        }).toList();
      } on Object catch (error) {
        lastError = error;
      } finally {
        if (_client == null) client.close();
      }
    }
    throw StateError('Holiday data unavailable for $year: $lastError');
  }
}
