// core/utils/map_cast.dart
//
// Recursively converts Map<dynamic, dynamic> (as returned by Hive CE)
// into Map<String, dynamic> so model fromJson() methods can safely cast.

/// Deep-casts a value that may be a nested Hive map into a
/// [Map<String, dynamic>]. Lists are recursively processed too.
///
/// If [value] is already a [Map<String, dynamic>], returns it as-is.
/// If [value] is a [Map<dynamic, dynamic>], converts all keys to [String]
/// and recursively casts nested maps and lists.
/// For any other type, returns [value] unchanged.
dynamic deepStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, v) => MapEntry(key.toString(), deepStringMap(v)));
  }
  if (value is List) return value.map(deepStringMap).toList();
  return value;
}

/// Convenience: deep-casts a top-level map to [Map<String, dynamic>].
///
/// Use this on data read from Hive CE before passing to model `fromJson()`.
Map<String, dynamic> asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, v) => MapEntry(key.toString(), deepStringMap(v)));
  }
  return <String, dynamic>{};
}
