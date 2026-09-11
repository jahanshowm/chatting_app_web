/// ADMIN API — 대시보드·회원·문의·결제·운영 REST
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/network/api_client.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';

class AdminApi {
  AdminApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) {
    return _client.postData('/admin/auth/login', data: {
      'username': username,
      'password': password,
      'remember_me': rememberMe,
    });
  }

  Future<AdminUser> me() => _client.getData('/admin/auth/me', fromJson: AdminUser.fromJson);

  Future<List<VisitorChartPoint>> visitors({
    required String period,
    String? startDate,
    String? endDate,
  }) {
    return _client.getListData(
      '/admin/dashboard/visitors',
      queryParameters: {
        'period': period,
        'start_date': ?startDate,
        'end_date': ?endDate,
      },
      fromJson: VisitorChartPoint.fromJson,
    );
  }

  Future<List<Map<String, dynamic>>> recentSignups() =>
      _client.getListData('/admin/dashboard/recent-signups', fromJson: (j) => j);

  Future<List<Map<String, dynamic>>> recentPayments() =>
      _client.getListData('/admin/dashboard/recent-payments', fromJson: (j) => j);

  Future<PaginatedResult<Map<String, dynamic>>> members({
    required String tab,
    int page = 1,
    String? filter,
    String? keyword,
    String? startDate,
    String? endDate,
  }) {
    return _client.getData(
      '/admin/members',
      queryParameters: {
        'tab': tab,
        'page': page,
        'filter': ?filter,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'start_date': ?startDate,
        'end_date': ?endDate,
      },
      fromJson: (j) => PaginatedResult.fromJson(j, (e) => e),
    );
  }

  Future<void> deleteMembers({required String tab, required List<String> ids}) async {
    await _client.deleteData(
      '/admin/members',
      data: {'ids': ids},
      queryParameters: {'tab': tab},
    );
  }

  Future<Map<String, dynamic>> updateMemberPhone({
    required String userId,
    required String phoneNumber,
  }) {
    return _client.patchData(
      '/admin/members/$userId/phone',
      data: {'phone_number': phoneNumber},
    );
  }

  Future<MemberDetail> memberDetail(String id) =>
      _client.getData('/admin/members/$id', fromJson: MemberDetail.fromJson);

  Future<PaginatedResult<Map<String, dynamic>>> memberActivities({
    required String userId,
    required String tab,
    int page = 1,
    int limit = 5,
  }) {
    return _client.getData(
      '/admin/members/$userId/activities',
      queryParameters: {'tab': tab, 'page': page, 'limit': limit},
      fromJson: (j) => PaginatedResult.fromJson(j, (e) => e),
    );
  }

  Future<PaymentListResult> payments({
    int page = 1,
    String? filter,
    String? keyword,
    String? startDate,
    String? endDate,
    String? period,
    String? userId,
  }) {
    return _client.getData(
      '/admin/payments',
      queryParameters: {
        'page': page,
        'filter': ?filter,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'start_date': ?startDate,
        'end_date': ?endDate,
        'period': ?period,
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
      },
      fromJson: PaymentListResult.fromJson,
    );
  }

  /// PG-01 — 체크된 결제내역 삭제
  Future<void> deletePayments(List<String> ids) =>
      _client.deleteData('/admin/payments', data: {'ids': ids});

  Future<PaginatedResult<Map<String, dynamic>>> inquiries({
    int page = 1,
    String? keyword,
    bool withdrawn = false,
    List<String>? statuses,
    String? userId,
  }) {
    return _client.getData(
      '/admin/inquiries',
      queryParameters: {
        'page': page,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'withdrawn': withdrawn,
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
        'statuses': ?statuses,
      },
      fromJson: (j) => PaginatedResult.fromJson(j, (e) => e),
    );
  }

  Future<InquiryThread> inquiryMessages(String id) =>
      _client.getData('/admin/inquiries/$id/messages', fromJson: InquiryThread.fromJson);

  Future<Map<String, dynamic>> sendInquiryMessage(
    String id, {
    String? content,
    String? imagePath,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    if (imageBytes != null && imageName != null) {
      final form = FormData.fromMap({
        if (content != null && content.isNotEmpty) 'content': content,
        'image': MultipartFile.fromBytes(imageBytes, filename: imageName),
      });
      return _client.postFormData('/admin/inquiries/$id/messages', formData: form);
    }
    return _client.postData('/admin/inquiries/$id/messages', data: {'content': content ?? ''});
  }

  Future<Map<String, dynamic>> updateInquiryStatus(String id, String status) =>
      _client.patchData('/admin/inquiries/$id/status', data: {'status': status});

  Future<PaginatedResult<Map<String, dynamic>>> notices({
    int page = 1,
    String? filter,
    String? keyword,
  }) {
    return _client.getData(
      '/admin/notices',
      queryParameters: {
        'page': page,
        // NTC-01-06 — 전체 필터도 명시 전달 (일자 검색 포함 분기)
        if (filter != null && filter.isNotEmpty) 'filter': filter,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
      fromJson: (j) => PaginatedResult.fromJson(j, (e) => e),
    );
  }

  Future<Map<String, dynamic>> noticeDetail(String id) =>
      _client.getData('/admin/notices/$id');

  Future<Map<String, dynamic>> createNotice(Map<String, dynamic> body) =>
      _client.postData('/admin/notices', data: body);

  Future<Map<String, dynamic>> updateNotice(String id, Map<String, dynamic> body) =>
      _client.patchData('/admin/notices/$id', data: body);

  Future<void> deleteNotices(List<String> ids) =>
      _client.deleteData('/admin/notices', data: {'ids': ids});

  Future<Map<String, dynamic>> popupDetail(String id) => _client.getData('/admin/popups/$id');

  Future<PaginatedResult<Map<String, dynamic>>> popups({
    int page = 1,
    String? filter,
    String? keyword,
  }) {
    return _client.getData(
      '/admin/popups',
      queryParameters: {
        'page': page,
        if (filter != null && filter != 'all') 'filter': filter,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
      fromJson: (j) => PaginatedResult.fromJson(j, (e) => e),
    );
  }

  Future<Map<String, dynamic>> createPopup(FormData formData) =>
      _client.postFormData('/admin/popups', formData: formData);

  Future<Map<String, dynamic>> updatePopup(String id, FormData formData) =>
      _client.patchFormData('/admin/popups/$id', formData: formData);

  Future<void> togglePopup(String id, bool isActive) =>
      _client.patchData('/admin/popups/$id/toggle', data: {'is_active': isActive});

  Future<void> deletePopups(List<String> ids) =>
      _client.deleteData('/admin/popups', data: {'ids': ids});

  Future<PaginatedResult<Map<String, dynamic>>> fcmCampaigns({
    int page = 1,
    String? startDate,
    String? endDate,
    String? keyword,
  }) {
    return _client.getData(
      '/admin/fcm',
      queryParameters: {
        'page': page,
        'start_date': ?startDate,
        'end_date': ?endDate,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
      fromJson: (j) => PaginatedResult.fromJson(j, (e) => e),
    );
  }

  Future<Map<String, dynamic>> fcmDetail(String id) => _client.getData('/admin/fcm/$id');

  Future<Map<String, dynamic>> createFcm(Map<String, dynamic> body) =>
      _client.postData('/admin/fcm', data: body);

  Future<Map<String, dynamic>> testFcm(Map<String, dynamic> body) =>
      _client.postData('/admin/fcm/test', data: body);

  Future<void> deleteFcmCampaigns(List<String> ids) =>
      _client.deleteData('/admin/fcm', data: {'ids': ids});

  Future<void> deleteInquiries(List<String> ids) =>
      _client.deleteData('/admin/inquiries', data: {'ids': ids});
}

final adminApiProvider = Provider<AdminApi>((ref) => AdminApi(ref.watch(apiClientProvider)));
