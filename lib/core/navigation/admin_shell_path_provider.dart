/// ADMIN NAV — CMS 내부 path 스택
library;
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

  void _popStack() {
    if (_stack.length <= 1) return;
    _stack.removeLast();
    state = _stack.last;
    _persist(state);
  }

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

  /// 브라우저(크롬 등) 뒤로가기(popstate) — 이전 CMS 화면으로, 루트면 /admin 유지.
  /// 바로 이전 화면이 같은 목록 path인데 기간 쿼리가 없으면, 상세 `from`으로 날짜를 채운다.
  /// (회원A→회원B 체인에서는 path가 다르므로 `from`으로 점프하지 않음)
  void handleBrowserBack() {
    if (_stack.length <= 1) {
      // 히스토리 끝 — 한 번 더 뒤로 나가기 전에 /admin 엔트리 다시 쌓음
      pushAdminBrowserHistory('/admin');
      return;
    }
    final leaving = _stack.last;
    _popStack();
    final from = _uriOf(leaving).queryParameters['from'];
    if (from != null && from.isNotEmpty) {
      _preferFallbackQuery(from);
    }
    // go_router/브라우저 URL이 / 로 바뀐 경우 /admin 으로 고정
    resetAdminBrowserHistory('/admin');
  }

  /// 「목록으로」— [fallbackPath](`from`)로 항상 복귀 (날짜·검색 쿼리 포함).
  /// 스택의 기간 없는 `/members/new`보다 `from`을 우선한다.
  void navigateBackOr(String fallbackPath) {
    if (fallbackPath.isEmpty) {
      handleBrowserBack();
      return;
    }

    if (!canPop) {
      setPathReplace(fallbackPath);
      return;
    }

    if (adminBrowserHistoryAvailable) {
      suppressNextAdminPopState();
      _popStack();
      setPathReplace(fallbackPath);
      goAdminBrowserBack();
      return;
    }

    _popStack();
    setPathReplace(fallbackPath);
  }

  /// 같은 목록 path일 때만 쿼리 있는 fallback으로 교체 (브라우저 뒤로가기용)
  void _preferFallbackQuery(String fallbackPath) {
    if (fallbackPath.isEmpty) return;
    final fallback = _uriOf(fallbackPath);
    final current = _uriOf(state);
    if (fallback.path != current.path) return;
    if (fallback.query.isEmpty) return;
    if (fallback.query == current.query) return;
    setPathReplace(fallbackPath);
  }

  static Uri _uriOf(String path) =>
      Uri.parse(path.startsWith('/') ? path : '/$path');
}

final adminShellPathProvider =
    NotifierProvider<AdminShellPathNotifier, String>(AdminShellPathNotifier.new);
