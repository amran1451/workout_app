/// String или int → int
int toIntId(dynamic raw) {
  if (raw is int) return raw;
  if (raw is String) return int.tryParse(raw) ?? 0;
  throw ArgumentError('Unexpected id type: ${raw.runtimeType}');
}
