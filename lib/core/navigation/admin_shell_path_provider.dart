import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_url_sync.dart';

class AdminShellPathNotifier extends Notifier<String> {
  final List<String> _stack = ['/dashboard'];

  @override
  String build() => '/dashboard';

  /// 사이드바 등 탭 전환 — 스택 push + 브라우저 history push (/admin URL 고정)
  void setPath(String path, {bool syncBrowserUrl = false}) {
    if (path.isEmpty || state == path) return;
    _stack.add(path);
    state = path;
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
  }

  /// 북마크/직접 URL 진입 — 스택 초기화, URL /admin 고정
  void setPathFromRedirect(String path) {
    if (path.isEmpty) return;
    _stack
      ..clear()
      ..add(path);
    state = path;
    resetAdminBrowserHistory('/admin');
  }

  void resetTo(String path) {
    _stack
      ..clear()
      ..add(path);
    state = path;
    resetAdminBrowserHistory('/admin');
  }

  /// 브라우저 뒤로가기 — 이전 CMS 탭으로, 루트면 /admin 유지
  void handleBrowserBack() {
    if (_stack.length <= 1) {
      pushAdminBrowserHistory('/admin');
      return;
    }
    _stack.removeLast();
    state = _stack.last;
  }
}

final adminShellPathProvider =
    NotifierProvider<AdminShellPathNotifier, String>(AdminShellPathNotifier.new);
