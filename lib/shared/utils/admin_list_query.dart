import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';

/// 목록 검색/기간 상태를 CMS path 쿼리에 넣어 뒤로가기·목록으로 시 복원.
class AdminListQuery {
  const AdminListQuery({
    required this.start,
    required this.end,
    this.period,
    this.filter = 'all',
    this.keyword = '',
    this.page = 1,
    this.statuses,
    this.extra = const {},
    this.persistDates = true,
  });

  final DateTime start;
  final DateTime end;
  final String? period;
  final String filter;
  final String keyword;
  final int page;
  /// 문의 상태 멀티필터 (all 제외)
  final Set<String>? statuses;
  /// user_id, from 등 목록 외 쿼리 유지
  final Map<String, String> extra;
  /// false면 start/end를 path에 넣지 않음 (문의·팝업·공지·신고차단 등)
  final bool persistDates;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime? tryParseApiDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final p = DateTime.tryParse(raw);
    if (p == null) return null;
    return dateOnly(p);
  }

  factory AdminListQuery.fromPath(
    String path, {
    DateTime? defaultStart,
    DateTime? defaultEnd,
    String? defaultPeriod,
    int defaultRangeDays = 0,
    bool persistDates = true,
  }) {
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    final q = uri.queryParameters;
    final today = AdminListQuery.today();
    final fallbackStart = defaultStart ??
        (defaultRangeDays > 0
            ? today.subtract(Duration(days: defaultRangeDays))
            : today);
    final fallbackEnd = defaultEnd ?? today;

    final start = tryParseApiDate(q['start']) ?? fallbackStart;
    final end = tryParseApiDate(q['end']) ?? fallbackEnd;
    final page = int.tryParse(q['page'] ?? '') ?? 1;
    final filter = (q['filter']?.isNotEmpty == true) ? q['filter']! : 'all';
    final keyword = q['q'] ?? '';
    // defaultPeriod는 대시보드·결제처럼 period를 쓰는 화면만 넘긴다
    final period = q['period'] ?? defaultPeriod;
    Set<String>? statuses;
    final statusRaw = q['status'];
    if (statusRaw != null && statusRaw.isNotEmpty) {
      statuses = statusRaw.split(',').where((e) => e.isNotEmpty).toSet();
    }

    const reserved = {
      'start',
      'end',
      'page',
      'filter',
      'q',
      'period',
      'status',
    };
    final extra = <String, String>{};
    q.forEach((k, v) {
      if (!reserved.contains(k) && v.isNotEmpty) extra[k] = v;
    });

    return AdminListQuery(
      start: start,
      end: end,
      period: period,
      filter: filter,
      keyword: keyword,
      page: page < 1 ? 1 : page,
      statuses: statuses,
      extra: extra,
      persistDates: persistDates,
    );
  }

  Map<String, String> toQueryParameters() {
    final map = <String, String>{
      ...extra,
      if (persistDates) ...{
        'start': DateRangeBar.formatApi(start),
        'end': DateRangeBar.formatApi(end),
      },
      if (period != null && period!.isNotEmpty) 'period': period!,
      if (filter.isNotEmpty && filter != 'all') 'filter': filter,
      if (keyword.trim().isNotEmpty) 'q': keyword.trim(),
      if (page > 1) 'page': '$page',
      if (statuses != null &&
          statuses!.isNotEmpty &&
          !statuses!.contains('all'))
        'status': statuses!.join(','),
    };
    return map;
  }

  String toPath(String basePath) {
    final base = Uri.parse(basePath.startsWith('/') ? basePath : '/$basePath');
    final params = toQueryParameters();
    if (params.isEmpty) return base.path;
    return Uri(path: base.path, queryParameters: params).toString();
  }

  bool sameAs(AdminListQuery other) {
    final datesOk = !persistDates && !other.persistDates
        ? true
        : DateRangeBar.formatApi(start) == DateRangeBar.formatApi(other.start) &&
            DateRangeBar.formatApi(end) == DateRangeBar.formatApi(other.end);
    return datesOk &&
        period == other.period &&
        filter == other.filter &&
        keyword.trim() == other.keyword.trim() &&
        page == other.page &&
        _setEq(_normalizeStatuses(statuses), _normalizeStatuses(other.statuses)) &&
        _mapEq(extra, other.extra);
  }

  static Set<String>? _normalizeStatuses(Set<String>? a) {
    if (a == null || a.isEmpty || a.contains('all')) return null;
    return a;
  }

  static bool _setEq(Set<String>? a, Set<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.length == b.length && a.containsAll(b);
  }

  static bool _mapEq(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

/// 스택 top만 교체해 필터를 히스토리에 남긴다 (뒤로가기 복원용).
void syncAdminListPath(WidgetRef ref, String basePath, AdminListQuery query) {
  adminNavigateReplace(ref, query.toPath(basePath));
}

String adminContentKeyForPath(String path) {
  final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
  return uri.path;
}
