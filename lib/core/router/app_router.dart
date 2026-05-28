import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randomchat_admin/core/providers/auth_provider.dart';
import 'package:randomchat_admin/features/auth/login_screen.dart';
import 'package:randomchat_admin/features/dashboard/dashboard_screen.dart';
import 'package:randomchat_admin/features/inquiries/inquiry_detail_screen.dart';
import 'package:randomchat_admin/features/inquiries/inquiry_list_screen.dart';
import 'package:randomchat_admin/features/members/member_detail_screen.dart';
import 'package:randomchat_admin/features/members/member_list_screen.dart';
import 'package:randomchat_admin/features/operations/operations_screens.dart';
import 'package:randomchat_admin/features/payments/payment_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      if (auth.loading) return null;
      if (!auth.isAuthenticated && !loggingIn) return '/login';
      if (auth.isAuthenticated && loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/members', builder: (_, __) => const MemberListScreen()),
      GoRoute(
        path: '/members/:id',
        builder: (_, state) => MemberDetailScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/payments', builder: (_, __) => const PaymentListScreen()),
      GoRoute(path: '/inquiries', builder: (_, __) => const InquiryListScreen()),
      GoRoute(
        path: '/inquiries/withdrawn',
        builder: (_, __) => const InquiryListScreen(withdrawn: true),
      ),
      GoRoute(
        path: '/inquiries/:id',
        builder: (_, state) => InquiryDetailScreen(inquiryId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/operations/popups', builder: (_, __) => const PopupListScreen()),
      GoRoute(path: '/operations/popups/new', builder: (_, __) => const PopupFormScreen()),
      GoRoute(
        path: '/operations/popups/:id/edit',
        builder: (_, state) => PopupFormScreen(popupId: state.pathParameters['id']),
      ),
      GoRoute(path: '/operations/fcm', builder: (_, __) => const FcmListScreen()),
      GoRoute(path: '/operations/fcm/new', builder: (_, __) => const FcmFormScreen()),
      GoRoute(path: '/operations/notices', builder: (_, __) => const NoticeListScreen()),
      GoRoute(path: '/operations/notices/new', builder: (_, __) => const NoticeFormScreen()),
      GoRoute(
        path: '/operations/notices/:id/edit',
        builder: (_, state) => NoticeFormScreen(noticeId: state.pathParameters['id']),
      ),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
