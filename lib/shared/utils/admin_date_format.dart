/// [initializeDateFormatting] 없이 쓸 수 있는 날짜·시간 포맷 (LocaleDataException 방지)
library;

/// API ISO 시각 → 기기 로컬 (문의·캠페인·팝업 공통)
DateTime parseApiDateTime(String raw) => DateTime.parse(raw).toLocal();

DateTime? tryParseApiDateTime(Object? raw) {
  if (raw == null) return null;
  final s = '$raw'.trim();
  if (s.isEmpty) return null;
  try {
    return parseApiDateTime(s);
  } catch (_) {
    return null;
  }
}

String formatYmdHmDots(DateTime dt) {
  final local = dt.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '${local.year}.$m.$d $h:$min';
}

String formatYmdApi(DateTime dt) {
  final local = dt.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$m-$d';
}

/// hh:mma (en_US) 대체 — 예: 10:30AM
String formatAmPmTime(DateTime dt) {
  final local = dt.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$m$period';
}

String formatYmdDots(DateTime dt) {
  final local = dt.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}.$m.$d';
}

/// Figma INQ-01-01 날짜 구분선 — 2026년 03월 29일
String formatKoreanDateDivider(DateTime dt) {
  final local = dt.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}년 $m월 $d일';
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}
