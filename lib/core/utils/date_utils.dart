import 'package:intl/intl.dart';

/// Parses a UTC timestamp string from Supabase.
///
/// Supabase `timestamp without time zone` columns return ISO strings
/// without trailing 'Z' or offset. Dart's [DateTime.tryParse] treats
/// such strings as local time, so we correct them to UTC.
///
/// TIMESTAMPTZ columns include 'Z' or offset, which [DateTime.tryParse]
/// handles correctly — this function is a no-op for those.
DateTime? parseSupabaseTimestamp(String? iso) {
  if (iso == null) return null;
  final dt = DateTime.tryParse(iso);
  if (dt == null) return null;
  if (dt.isUtc) return dt;
  return DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute,
      dt.second, dt.millisecond, dt.microsecond);
}

/// Calendar-day comparison — uses midnight boundaries, not 24-hour rolling window.
int _calendarDaysAgo(DateTime localTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(localTime.year, localTime.month, localTime.day);
  return today.difference(msgDay).inDays;
}

/// WhatsApp-style relative date for a UTC DateTime (parsed from Supabase).
/// Returns e.g. "8:02 PM", "Yesterday", "Monday", or "7/1/26".
String relativeDate(DateTime? utcDt) {
  if (utcDt == null) return '';
  final local = utcDt.toLocal();
  final daysAgo = _calendarDaysAgo(local);
  if (daysAgo == 0) return DateFormat.jm().format(local);
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) return DateFormat.EEEE().format(local);
  return DateFormat('M/d/yy').format(local);
}

/// Full "last seen" text for the chat detail header.
/// Returns e.g. "last seen today at 8:02 PM", "last seen yesterday at 3:15 PM",
/// or "last seen 7/1/26" for older dates.
String lastSeenText(DateTime? utcDt) {
  if (utcDt == null) return '';
  final local = utcDt.toLocal();
  final daysAgo = _calendarDaysAgo(local);
  final timeOnly = DateFormat.jm().format(local);
  if (daysAgo == 0) return 'last seen today at $timeOnly';
  if (daysAgo == 1) return 'last seen yesterday at $timeOnly';
  if (daysAgo < 7) return 'last seen ${DateFormat.EEEE().format(local)} at $timeOnly';
  return 'last seen ${DateFormat('M/d/yy').format(local)}';
}

/// Date separator label — "Today", "Yesterday", weekday name, or "MMMM d, yyyy".
String dateSeparatorLabel(DateTime utcDt) {
  final local = utcDt.toLocal();
  final daysAgo = _calendarDaysAgo(local);
  if (daysAgo == 0) return 'Today';
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) return DateFormat.EEEE().format(local);
  return DateFormat('MMMM d, yyyy').format(local);
}

/// Message bubble timestamp — returns time-only (e.g. "5:06 PM").
/// Date separators handle date/weekday display; bubbles should never
/// duplicate that information.
String messageBubbleTime(String? iso) {
  if (iso == null) return '';
  final dt = parseSupabaseTimestamp(iso);
  if (dt == null) return '';
  return DateFormat.jm().format(dt.toLocal());
}
