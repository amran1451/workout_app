int toIntId(dynamic rawId) {
  if (rawId is int) return rawId;
  if (rawId is String) return int.tryParse(rawId) ?? 0;
  throw ArgumentError('Unexpected id type: ${rawId.runtimeType}');
}
