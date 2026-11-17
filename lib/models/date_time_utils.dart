DateTime parseUtcIso8601(String value) {
  final parsed = DateTime.parse(value);
  if (parsed.isUtc) return parsed;
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}

String relativeTimeLabel(DateTime time, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(time);
  if (difference.isNegative || difference.inMinutes < 1) return 'baru saja';
  if (difference.inMinutes < 60) return '${difference.inMinutes} menit lalu';
  if (difference.inHours < 24) return '${difference.inHours} jam lalu';
  if (difference.inDays == 1) return 'kemarin';
  if (difference.inDays < 7) return '${difference.inDays} hari lalu';
  return '${difference.inDays ~/ 7} minggu lalu';
}
