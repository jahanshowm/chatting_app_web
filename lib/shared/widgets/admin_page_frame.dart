import 'package:flutter/material.dart';

/// Figma 메인 콘텐츠 영역 패딩 (breadcrumb는 AdminShell 헤더)
class AdminContentArea extends StatelessWidget {
  const AdminContentArea({
    super.key,
    required this.child,
    this.toolbar,
    this.summary,
  });

  final Widget child;
  final Widget? toolbar;
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
