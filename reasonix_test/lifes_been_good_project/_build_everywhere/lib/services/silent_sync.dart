import 'dart:collection';
import 'dart:convert';

String stableDataSignature(Object? value) {
  return jsonEncode(_normalizeStableValue(value));
}

Object? _normalizeStableValue(Object? value) {
  if (value is Map) {
    final sorted = SplayTreeMap<String, Object?>();
    for (final entry in value.entries) {
      sorted[entry.key.toString()] = _normalizeStableValue(entry.value);
    }
    return sorted;
  }
  if (value is Iterable) {
    return value.map(_normalizeStableValue).toList(growable: false);
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  return value;
}
