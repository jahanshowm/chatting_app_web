/// ADMIN ROUTER — /login·/admin 라우트·인증 redirect
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randomchat_admin/core/navigation/admin_shell_path_provider.dart';
import 'package:randomchat_admin/core/providers/auth_provider.dart';
import 'package:randomchat_admin/features/auth/login_screen.dart';
import 'package:randomchat_admin/features/layout/admin_app_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshListenable(ref);

  return GoRouter(
    // 새로고침 시 /login 깜빡임 방지 — 토큰 복원 전에도 /admin 유지
    initialLocation: '/admin',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.uri.path;
      final onLogin = path == '/login';
      final onAdmin = path == '/admin';

      // 부트스트랩 중에는 로그인으로 보내지 않음 (반드시 로그인 화면을 거칠 필요 없음)
      if (auth.loading) {
        if (onLogin) return '/admin';
        return null;
      }
      if (!auth.isAuthenticated && !onLogin) return '/login';
      if (auth.isAuthenticated && onLogin) return '/admin';

      // 북마크/새로고침: /members/new 등 직접 URL → provider에만 반영, URL은 /admin 고정
      // `/` 는 브라우저 뒤로가기 과정에서 잠깐 나타날 수 있음 → 스택 리셋 금지
      if (auth.isAuthenticated && !onLogin && !onAdmin) {
        if (path != '/' && path.isNotEmpty) {
          ref.read(adminShellPathProvider.notifier).setPathFromRedirect(path);
        }
        return '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminAppPage()),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }

  final Ref ref;
}
