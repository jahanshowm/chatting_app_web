import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/navigation/admin_shell_path_provider.dart';

class AdminMenuItem {
  const AdminMenuItem({
    required this.label,
    required this.path,
  });

  final String label;
  final String path;
}

class AdminMenuSection {
  const AdminMenuSection({
    required this.label,
    required this.items,
  });

  final String label;
  final List<AdminMenuItem> items;

  bool matchesPath(String path) => items.any((i) => _pathMatches(i.path, path));

  static bool _pathMatches(String menuPath, String current) {
    if (menuPath == current) return true;
    if (menuPath == '/members/report-block') {
      return current.startsWith('/members/report-block') ||
          current.startsWith('/members/reports') ||
          current.startsWith('/members/blocks');
    }
    if (menuPath == '/members/new') {
      final parts = current.split('/');
      if (parts.length == 3 && parts[1] == 'members' && parts[2].length > 12) {
        return true;
      }
    }
    if (menuPath.startsWith('/members/') && current.startsWith('/members/')) {
      final segments = current.split('/');
      if (segments.length == 3 && segments[2].length > 20) {
        return menuPath == '/members/new';
      }
    }
    return current.startsWith('$menuPath/') || (menuPath != '/' && current.startsWith(menuPath));
  }
}

/// Figma `관리자페이지` 사이드바 (node 1:5143) — 1:1
const adminMenuSections = <AdminMenuSection>[
  AdminMenuSection(
    label: '대시보드',
    items: [AdminMenuItem(label: '대시보드', path: '/dashboard')],
  ),
  AdminMenuSection(
    label: '회원 관리',
    items: [
      AdminMenuItem(label: '신규회원', path: '/members/new'),
      AdminMenuItem(label: '탈퇴회원', path: '/members/withdrawn'),
      AdminMenuItem(label: '신고 및 차단회원', path: '/members/report-block'),
    ],
  ),
  AdminMenuSection(
    label: '결제내역',
    items: [AdminMenuItem(label: '결제내역', path: '/payments')],
  ),
  AdminMenuSection(
    label: '문의내역',
    items: [
      AdminMenuItem(label: '활동 회원', path: '/inquiries/active'),
      AdminMenuItem(label: '탈퇴 회원', path: '/inquiries/withdrawn'),
    ],
  ),
  AdminMenuSection(
    label: '운영관리',
    items: [
      AdminMenuItem(label: '팝업 관리', path: '/operations/popups'),
      AdminMenuItem(label: 'FCM', path: '/operations/fcm'),
      AdminMenuItem(label: '공지사항', path: '/operations/notices'),
    ],
  ),
];

/// Figma breadcrumb: `회원 관리 > 신규회원`
class AdminBreadcrumb {
  const AdminBreadcrumb({required this.section, this.item});

  final String section;
  final String? item;

  String get text => item == null ? section : '$section > $item';
}

AdminBreadcrumb adminBreadcrumbForPath(String path) {
  for (final section in adminMenuSections) {
    for (final item in section.items) {
      if (item.path == path) {
        return AdminBreadcrumb(
          section: section.label,
          item: section.items.length == 1 ? null : item.label,
        );
      }
    }
  }

  if (path.startsWith('/members/report-block') ||
      path.startsWith('/members/reports') ||
      path.startsWith('/members/blocks')) {
    return const AdminBreadcrumb(section: '회원 관리', item: '신고 및 차단회원');
  }

  if (path.startsWith('/members/') && path.split('/').length == 3) {
    final seg = path.split('/')[2];
    if (!{'new', 'withdrawn', 'report-block', 'reports', 'blocks'}.contains(seg)) {
      return const AdminBreadcrumb(section: '회원 관리', item: '회원 상세');
    }
  }

  if (path.startsWith('/inquiries/') &&
      path != '/inquiries/active' &&
      path != '/inquiries/withdrawn') {
    return const AdminBreadcrumb(section: '문의내역', item: '문의 답변');
  }

  if (path.contains('/operations/popups/new')) {
    return const AdminBreadcrumb(section: '운영관리', item: '팝업 등록');
  }
  if (path.contains('/operations/popups/') && path.contains('/edit')) {
    return const AdminBreadcrumb(section: '운영관리', item: '팝업 수정');
  }
  if (path.contains('/operations/fcm/new')) {
    return const AdminBreadcrumb(section: '운영관리', item: 'FCM 발송');
  }
  if (path.contains('/operations/notices/new')) {
    return const AdminBreadcrumb(section: '운영관리', item: '공지 등록');
  }
  if (path.contains('/operations/notices/') && path.contains('/edit')) {
    return const AdminBreadcrumb(section: '운영관리', item: '공지 수정');
  }

  return const AdminBreadcrumb(section: '관리자');
}

void adminNavigate(WidgetRef ref, String path) {
  ref.read(adminShellPathProvider.notifier).setPath(path);
}

void adminNavigateReplace(WidgetRef ref, String path) {
  ref.read(adminShellPathProvider.notifier).setPath(path);
}
