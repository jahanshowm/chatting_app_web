import 'package:flutter/material.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';

/// Figma CMS 화면 ID · 부제 (breadcrumb는 AdminShell 헤더)
class AdminScreenMeta extends StatelessWidget {
  const AdminScreenMeta({super.key, this.id, this.subtitle});

  final String? id;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (id == null && (subtitle == null || subtitle!.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (id != null) ...[
          Text(
            id!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '·',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 8),
          ],
        ],
        if (subtitle != null && subtitle!.isNotEmpty)
          Expanded(
            child: Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

/// 회원 필터 바로가기 시 상단 안내
class UserFilterBanner extends StatelessWidget {
  const UserFilterBanner({
    super.key,
    required this.userId,
    required this.onClear,
    this.label = '회원별 조회 중',
  });

  final String userId;
  final VoidCallback onClear;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.primary.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label (ID: ${userId.length > 8 ? '${userId.substring(0, 8)}…' : userId})',
              style: const TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('전체 보기')),
        ],
      ),
    );
  }
}

/// Figma 메인 콘텐츠 영역 패딩 (breadcrumb는 AdminShell 헤더)
class AdminContentArea extends StatelessWidget {
  const AdminContentArea({
    super.key,
    required this.child,
    this.toolbar,
    this.summary,
    this.screenId,
    this.subtitle,
  });

  final Widget child;
  final Widget? toolbar;
  final Widget? summary;
  final String? screenId;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (screenId != null || subtitle != null) ...[
            AdminScreenMeta(id: screenId, subtitle: subtitle),
            const SizedBox(height: 12),
          ],
          if (toolbar != null) ...[
            toolbar!,
            const SizedBox(height: 16),
          ],
          if (summary != null) ...[
            summary!,
            const SizedBox(height: 16),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}
