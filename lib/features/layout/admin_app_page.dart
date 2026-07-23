/// ADMIN — 셸 + content host 조립
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/navigation/admin_shell_path_provider.dart';
import 'package:randomchat_admin/core/navigation/admin_url_sync.dart';
import 'package:randomchat_admin/features/layout/admin_content_host.dart';
import 'package:randomchat_admin/shared/widgets/admin_shell.dart';

class AdminAppPage extends ConsumerWidget {
  const AdminAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ensureAdminPopStateInstalled(() {
      ref.read(adminShellPathProvider.notifier).handleBrowserBack();
    });

    final path = ref.watch(adminShellPathProvider);
    return AdminShell(
      child: AdminContentHost(key: ValueKey(path), path: path),
    );
  }
}
