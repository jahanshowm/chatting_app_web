/// ADMIN — DTO·페이지네이션 모델
class PaginatedResult<T> {
  PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasNext,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final bool hasNext;

  int get totalPages => (total / limit).ceil().clamp(1, 999999);

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    return PaginatedResult(
      items: itemsRaw.map((e) => fromItem(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}

class AdminUser {
  AdminUser({required this.id, required this.username, this.name});

  final String id;
  final String username;
  final String? name;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        username: json['username'] as String,
        name: json['name'] as String?,
      );
}

class VisitorChartPoint {
  VisitorChartPoint({
    required this.label,
    required this.male,
    required this.female,
    required this.total,
  });

  final String label;
  final int male;
  final int female;
  final int total;

  factory VisitorChartPoint.fromJson(Map<String, dynamic> json) => VisitorChartPoint(
        label: json['label'] as String? ?? '',
        male: _readInt(json['male']),
        female: _readInt(json['female']),
        total: _readInt(json['total']),
      );
}

int _readInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class MemberRow {
  MemberRow({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  factory MemberRow.fromJson(Map<String, dynamic> json) => MemberRow(
        id: json['id'] as String,
        data: json,
      );
}

class MemberDetail {
  MemberDetail({required this.data});

  final Map<String, dynamic> data;

  factory MemberDetail.fromJson(Map<String, dynamic> json) => MemberDetail(data: json);

  String get id => data['id'] as String;
  String get name => data['name'] as String? ?? '-';
  String get nickname => data['nickname'] as String? ?? '-';
  List<String> get photos =>
      (data['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
}

class PaymentListResult {
  PaymentListResult({required this.page, required this.selectedSum});

  final PaginatedResult<Map<String, dynamic>> page;
  final int selectedSum;

  factory PaymentListResult.fromJson(Map<String, dynamic> json) => PaymentListResult(
        page: PaginatedResult.fromJson(json, (e) => e),
        selectedSum: json['selected_sum'] as int? ?? 0,
      );
}

class InquiryThread {
  InquiryThread({required this.inquiry, required this.member, required this.messages});

  final Map<String, dynamic> inquiry;
  final Map<String, dynamic> member;
  final List<Map<String, dynamic>> messages;

  factory InquiryThread.fromJson(Map<String, dynamic> json) => InquiryThread(
        inquiry: json['inquiry'] as Map<String, dynamic>,
        member: json['member'] as Map<String, dynamic>,
        messages: (json['messages'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
      );
}
