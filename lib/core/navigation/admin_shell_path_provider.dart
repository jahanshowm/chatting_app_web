/// ADMIN NAV — CMS 내부 path 스택
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_url_sync.dart';

class AdminShellPathNotifier extends Notifier<String> {
  final List<String> _stack = [];

  @override
  String build() {
    // NTC-01-06 — 새로고침 시 대시보드로 떨어지지 않도록 복원
    final restored = readPersistedAdminCmsPath();
    final initial =
        (restored != null && restored.isNotEmpty) ? restored : '/dashboard';
    _stack.add(initial);
    return initial;
  }

  void _persist(String path) => persistAdminCmsPath(path);

  /// 사이드바 등 탭 전환 — 스택 push + 브라우저 history push (/admin URL 고정)
  void setPath(String path, {bool syncBrowserUrl = false}) {
    if (path.isEmpty || state == path) return;
    _stack.add(path);
    state = path;
    _persist(path);
    if (syncBrowserUrl) {
      replaceAdminBrowserUrl(path);
    } else {
      pushAdminBrowserHistory('/admin');
    }
  }

  /// 목록 필터·페이지·상세↔목록 — 스택 top만 교체, history 추가 없음
  void setPathReplace(String path) {
    if (path.isEmpty || state == path) return;
    if (_stack.isEmpty) {
      _stack.add(path);
    } else {
      _stack[_stack.length - 1] = path;
    }
    state = path;
    _persist(path);
  }

  /// 북마크/직접 URL 진입 — 스택 초기화, URL /admin 고정
  void setPathFromRedirect(String path) {
    if (path.isEmpty ||
        path == '/' ||
        path == '/admin' ||
        path == '/login') {
      return;
    }
    _stack
      ..clear()
      ..add(path);
    state = path;
    _persist(path);
    resetAdminBrowserHistory('/admin');
  }

  void resetTo(String path) {
    _stack
      ..clear()
      ..add(path);
    state = path;
    _persist(path);
    resetAdminBrowserHistory('/admin');
  }

  bool get canPop => _stack.length > 1;

  /// 브라우저(크롬 등) 뒤로가기(popstate) — 이전 CMS 화면으로, 루트면 /admin 유지
  void handleBrowserBack() {
    if (_stack.length <= 1) {
      // 히스토리 끝 — URL이 / 로 떨어져도 CMS는 /admin 유지
      resetAdminBrowserHistory('/admin');
      return;
    }
    _stack.removeLast();
    state = _stack.last;
    _persist(state);
    // go_router/브라우저 URL이 / 로 바뀐 경우 /admin 으로 고정
    resetAdminBrowserHistory('/admin');
  }

  /// 「목록으로」등 — 스택이 있으면 브라우저(크롬) history.back()과 동일
  void navigateBackOr(String fallbackPath) {
    if (canPop) {
      if (adminBrowserHistoryAvailable) {
        goAdminBrowserBack();
      } else {
        handleBrowserBack();
      }
      return;
    }
    setPathReplace(fallbackPath);
  }
}

final adminShellPathProvider =
    NotifierProvider<AdminShellPathNotifier, String>(AdminShellPathNotifier.new);
