// Shared formatting utilities — eliminates duplicated _formatTime methods
// across jadwal_card and today_schedule.

/// Formats a [DateTime] as HH:MM (24-hour zero-padded).
String formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
