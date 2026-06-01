import 'package:flutter/material.dart';
import 'package:randomchat_admin/features/dashboard/dashboard_screen.dart';
import 'package:randomchat_admin/features/inquiries/inquiry_detail_screen.dart';
import 'package:randomchat_admin/features/inquiries/inquiry_list_screen.dart';
import 'package:randomchat_admin/features/members/member_detail_screen.dart';
import 'package:randomchat_admin/features/members/member_list_screen.dart';
import 'package:randomchat_admin/features/members/member_report_block_screen.dart';
import 'package:randomchat_admin/features/operations/operations_screens.dart';
import 'package:randomchat_admin/features/payments/payment_list_screen.dart';

/// go_router 없이 path 문자열만으로 CMS 콘텐츠 위젯 선택
class AdminContentHost extends StatelessWidget {
  const AdminContentHost({super.key, required this.path});

  final String path;

  static const _memberTabs = {'new', 'withdrawn', 'report-block', 'reports', 'blocks'};

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    final segments = uri.pathSegments;

    if (path == '/dashboard' || segments.isEmpty) {
      return const DashboardScreen();
    }

    if (segments.first == 'members') {
      if (segments.length >= 2 && !_memberTabs.contains(segments[1])) {
        final from = uri.queryParameters['from'] ?? '/members/new';
        return MemberDetailScreen(userId: segments[1], listPath: from);
      }
      final tab = segments.length >= 2 ? segments[1] : 'new';
      if (tab == 'report-block' || tab == 'reports' || tab == 'blocks') {
        return MemberReportBlockScreen(
          initialTab: tab == 'blocks' ? 'block' : 'report',
        );
      }
      final apiTab = switch (tab) {
        'withdrawn' => 'withdrawn',
        _ => 'new',
      };
      return MemberListScreen(tab: apiTab);
    }

    if (segments.first == 'payments') {
      return PaymentListScreen(userId: uri.queryParameters['user_id']);
    }

    if (segments.first == 'inquiries') {
      if (segments.length >= 2 && segments[1] != 'active' && segments[1] != 'withdrawn') {
        final from = uri.queryParameters['from'] ?? '/inquiries/active';
        return InquiryDetailScreen(inquiryId: segments[1], listPath: from);
      }
      return InquiryListScreen(
        withdrawn: segments.length >= 2 && segments[1] == 'withdrawn',
        userId: uri.queryParameters['user_id'],
      );
    }

    if (segments.first == 'operations') {
      if (segments.length == 1) {
        return const PopupListScreen();
      }
      if (segments.length >= 2 && segments[1] == 'popups') {
        if (segments.length >= 3 && segments[2] == 'new') return const PopupFormScreen();
        if (segments.length >= 4 && segments[3] == 'edit') {
          return PopupFormScreen(popupId: segments[2]);
        }
        return const PopupListScreen();
      }
      if (segments.length >= 2 && segments[1] == 'fcm') {
        if (segments.length >= 3 && segments[2] == 'new') {
          final sendMethod = uri.queryParameters['send_method'] ?? 'immediate';
          final scheduledRaw = uri.queryParameters['scheduled_at'];
          DateTime? scheduledAt;
          if (scheduledRaw != null && scheduledRaw.isNotEmpty) {
            scheduledAt = DateTime.tryParse(scheduledRaw);
          }
          if (segments.length >= 4 && segments[3] == 'all') {
            return FcmAllSendFormScreen(sendMethod: sendMethod, scheduledAt: scheduledAt);
          }
          if (segments.length >= 4 && segments[3] == 'target') {
            return FcmTargetSendFormScreen(sendMethod: sendMethod, scheduledAt: scheduledAt);
          }
          return const FcmSendTypeScreen();
        }
        if (segments.length >= 3) {
          return FcmDetailScreen(campaignId: segments[2]);
        }
        return const FcmListScreen();
      }
      if (segments.length >= 2 && segments[1] == 'notices') {
        if (segments.length >= 3 && segments[2] == 'new') return const NoticeFormScreen();
        if (segments.length >= 4 && segments[3] == 'edit') {
          return NoticeFormScreen(noticeId: segments[2]);
        }
        return const NoticeListScreen();
      }
    }

    return const DashboardScreen();
  }
}
