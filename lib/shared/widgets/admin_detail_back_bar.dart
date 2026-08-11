import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';

/// 상세/폼 상단 「목록으로」— 가능하면 브라우저 history.back()과 동일하게 복귀
class AdminDetailBackBar extends ConsumerWidget {
  const AdminDetailBackBar({super.key, required this.backPath, this.label = '목록으로'});

  final String backPath;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextButton.icon(
        onPressed: () => adminNavigateBack(ref, backPath),
        icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textSecondary),
        label: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        style: TextButton.styleFrom(alignment: Alignment.centerLeft),
      ),
    );
  }
}
