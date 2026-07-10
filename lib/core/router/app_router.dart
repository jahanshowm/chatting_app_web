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
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.uri.path;
      final onLogin = path == '/login';
      final onAdmin = path == '/admin';

      if (auth.loading) return null;
      if (!auth.isAuthenticated && !onLogin) return '/login';
      if (auth.isAuthenticated && onLogin) return '/admin';

      // 북마크/새로고침: /members/new 등 직접 URL → provider에만 반영, URL은 /admin 고정
      if (auth.isAuthenticated && !onLogin && !onAdmin) {
        ref.read(adminShellPathProvider.notifier).setPathFromRedirect(path);
        return '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminAppPage()),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
