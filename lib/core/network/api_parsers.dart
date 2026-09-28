import '../errors/app_exception.dart';

Map<String, dynamic> requireJsonMap(
  Object? value, {
  String description = 'response',
}) {
  final Object? unwrapped = unwrapApiData(value);
  if (unwrapped is Map) return Map<String, dynamic>.from(unwrapped);
  throw AppException('The server returned an invalid $description.');
}

List<Map<String, dynamic>> requireJsonMapList(
  Object? value, {
  String description = 'response',
}) {
  final Object? unwrapped = unwrapApiData(value);
  if (unwrapped is! List) {
    throw AppException('The server returned an invalid $description.');
  }
  return unwrapped
      .map<Map<String, dynamic>>((Object? item) {
        if (item is! Map) {
          throw AppException(
            'The server returned an invalid $description item.',
          );
        }
        return Map<String, dynamic>.from(item);
      })
      .toList(growable: false);
}

/// Accepts direct FastAPI responses and common `{data: ...}` envelopes.
Object? unwrapApiData(Object? value) {
  if (value is! Map) return value;
  final Map<String, dynamic> map = Map<String, dynamic>.from(value);
  if (map.containsKey('data')) return map['data'];
  if (map.containsKey('result')) return map['result'];
  return map;
}

String? firstString(Map<String, dynamic> json, Iterable<String> keys) {
  for (final String key in keys) {
    final Object? value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

int? firstInt(Map<String, dynamic> json, Iterable<String> keys) {
  for (final String key in keys) {
    final Object? value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    final int? parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

double? firstDouble(Map<String, dynamic> json, Iterable<String> keys) {
  for (final String key in keys) {
    final Object? value = json[key];
    if (value is num) return value.toDouble();
    final double? parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? firstDateTime(Map<String, dynamic> json, Iterable<String> keys) {
  final String? value = firstString(json, keys);
  return value == null ? null : DateTime.tryParse(value);
}

/// Reads a timestamp as the clock time it states, as a local DateTime:
/// `2016-11-11T14:30:00+02:00` becomes 11 Nov 2016, 14:30.
///
/// Use it for times people are told to show up at, such as event start
/// times, which are set in Jordan time. [firstDateTime] turns the example
/// into 12:30 UTC, which the formatters would print as 12:30 PM.
///
/// A `Z` (UTC) time names no local clock, so it is shown in the phone's
/// time zone instead.
DateTime? firstWallClockDateTime(
  Map<String, dynamic> json,
  Iterable<String> keys,
) {
  final String? value = firstString(json, keys)?.trim();
  if (value == null) return null;
  final RegExpMatch? match = _offsetTimestamp.firstMatch(value);
  if (match == null) return DateTime.tryParse(value)?.toLocal();
  return DateTime.tryParse(match.group(1)!);
}

// Date and time followed by a `±hh:mm` offset; group 1 is the part before
// the offset.
final RegExp _offsetTimestamp = RegExp(
  r'^(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?)'
  r'[+-]\d{2}(?::?\d{2})?$',
);
