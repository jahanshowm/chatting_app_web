/// ADMIN — 사이드바·헤더 breadcrumb 레이아웃
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/navigation/admin_shell_path_provider.dart';
import 'package:randomchat_admin/core/providers/auth_provider.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const sidebarWidth = 305.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(adminShellPathProvider);
    final breadcrumb = adminBreadcrumbForPath(path);

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(currentPath: path),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          breadcrumb.text,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            ref.read(adminShellPathProvider.notifier).resetTo('/dashboard');
                            context.go('/login');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SidebarBody(
      currentPath: currentPath,
      onNavigate: (path) => adminNavigate(ref, path),
    );
  }
}

class _SidebarBody extends StatefulWidget {
  const _SidebarBody({
    required this.currentPath,
    required this.onNavigate,
  });

  final String currentPath;
  final ValueChanged<String> onNavigate;

  @override
  State<_SidebarBody> createState() => _SidebarBodyState();
}

class _SidebarBodyState extends State<_SidebarBody> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _syncExpanded(widget.currentPath);
  }

  @override
  void didUpdateWidget(_SidebarBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      final before = Set<String>.from(_expanded);
      _syncExpanded(
        widget.currentPath,
        previousPath: oldWidget.currentPath,
      );
      if (!_setEquals(before, _expanded)) {
        setState(() {});
      }
    }
  }

  void _syncExpanded(String path, {String? previousPath}) {
    // DAS-01 — 다른 섹션으로 이동할 때만 해당 섹션을 연다.
    // 같은 섹션 내 이동(상세 등)에서는 사용자가 닫아 둔 상태를 유지.
    String? matched;
    for (final section in adminMenuSections) {
      if (section.items.length > 1 && section.matchesPath(path)) {
        matched = section.label;
        break;
      }
    }
    if (matched == null) return;

    String? prevMatched;
    if (previousPath != null) {
      for (final section in adminMenuSections) {
        if (section.items.length > 1 && section.matchesPath(previousPath)) {
          prevMatched = section.label;
          break;
        }
      }
    }

    if (prevMatched == matched) return;

    _expanded
      ..clear()
      ..add(matched);
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  bool _isSelected(AdminMenuItem item) {
    final uri = Uri.parse(
      widget.currentPath.startsWith('/')
          ? widget.currentPath
          : '/${widget.currentPath}',
    );
    final path = uri.path;
    final from = uri.queryParameters['from'];

    if (item.path == path) return true;
    if (item.path == '/members/report-block') {
      return path.startsWith('/members/report-block') ||
          path.startsWith('/members/reports') ||
          path.startsWith('/members/blocks');
    }
    if (item.path == '/members/new') {
      final parts = path.split('/');
      if (parts.length == 3 && parts[1] == 'members' && parts[2].length > 12) {
        return true;
      }
    }
    // INQ-01-02 — 문의 상세는 ?from= 기준으로 활동/탈퇴 메뉴 유지
    if (path.startsWith('/inquiries/') &&
        path != '/inquiries/active' &&
        path != '/inquiries/withdrawn') {
      if (item.path == '/inquiries/withdrawn') {
        return from == '/inquiries/withdrawn';
      }
      if (item.path == '/inquiries/active') {
        return from != '/inquiries/withdrawn';
      }
    }
    return path.startsWith('${item.path}/');
  }

  bool _sectionActive(AdminMenuSection section) => section.matchesPath(widget.currentPath);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AdminShell.sidebarWidth,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '랜덤채팅',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '스몰톡',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final section in adminMenuSections) ...[
                  if (section.items.length == 1)
                    _SidebarMainItem(
                      label: section.label,
                      selected: _sectionActive(section),
                      onTap: () => widget.onNavigate(section.items.first.path),
                    )
                  else ...[
                    _SidebarSectionHeader(
                      label: section.label,
                      expanded: _expanded.contains(section.label),
                      active: _sectionActive(section),
                      onTap: () {
                        // DAS-01 — 한 번의 클릭으로 열기/닫기 (active여도 강제 고정 금지)
                        final wasOpen = _expanded.contains(section.label);
                        setState(() {
                          _expanded.clear();
                          if (!wasOpen) {
                            _expanded.add(section.label);
                          }
                        });
                        if (!wasOpen && !_sectionActive(section)) {
                          widget.onNavigate(section.items.first.path);
                        }
                      },
                    ),
                    if (_expanded.contains(section.label))
                      for (final item in section.items)
                        _SidebarSubItem(
                          label: item.label,
                          selected: _isSelected(item),
                          onTap: () => widget.onNavigate(item.path),
                        ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMainItem extends StatelessWidget {
  const _SidebarMainItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.sidebarActive : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSectionHeader extends StatelessWidget {
  const _SidebarSectionHeader({
    required this.label,
    required this.expanded,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active && !expanded ? AppColors.sidebarActive.withValues(alpha: 0.6) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  const _SidebarSubItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.sidebarActive : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 12, 32, 12),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
