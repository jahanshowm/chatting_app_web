/// ADMIN — 셸 + content host 조립
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/navigation/admin_shell_path_provider.dart';
import 'package:randomchat_admin/core/providers/auth_provider.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/features/layout/admin_content_host.dart';
import 'package:randomchat_admin/shared/utils/admin_list_query.dart';
import 'package:randomchat_admin/shared/widgets/admin_shell.dart';

class AdminAppPage extends ConsumerWidget {
  const AdminAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    // 토큰 복원 중 — 로그인 화면 대신 로딩만 표시
    if (auth.loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!auth.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final path = ref.watch(adminShellPathProvider);
    // 쿼리(날짜·검색) 변경만으로는 remount 하지 않음 — path 세그먼트 기준
    return AdminShell(
      child: AdminContentHost(
        key: ValueKey(adminContentKeyForPath(path)),
        path: path,
      ),
    );
  }
}
