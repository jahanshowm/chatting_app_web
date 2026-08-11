// Web 전용 URL sync (조건부 import). dart:html 사용이 의도됨.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const _kCmsPathKey = 'admin_cms_path';

void replaceAdminBrowserUrl(String path) {
  html.window.history.replaceState(null, '', path);
}

void resetAdminBrowserHistory(String path) {
  html.window.history.replaceState(null, '', path);
}

/// CMS 내부 탭 이동 — URL은 /admin 고정, history만 쌓아 popstate로 이전 탭 복원
void pushAdminBrowserHistory(String path) {
  html.window.history.pushState(null, '', path);
}

/// CMS-02 — 크롬 등 브라우저 뒤로가기와 동일 (history.back → popstate)
bool get adminBrowserHistoryAvailable => true;

void goAdminBrowserBack() {
  html.window.history.back();
}

bool _popStateInstalled = false;
void Function()? _onPopState;
bool _suppressNextPopState = false;

/// 「목록으로」에서 스택을 먼저 pop한 뒤 history.back() 할 때 — 이중 pop 방지
void suppressNextAdminPopState() {
  _suppressNextPopState = true;
}

/// popstate 핸들러. 리스너는 앱 생애주기 동안 1회, [onPop]은 최신으로 교체.
void ensureAdminPopStateInstalled(void Function() onPop) {
  _onPopState = onPop;
  if (_popStateInstalled) return;
  _popStateInstalled = true;
  html.window.onPopState.listen((_) {
    if (_suppressNextPopState) {
      _suppressNextPopState = false;
      // history.back() 직후 URL 보정
      resetAdminBrowserHistory('/admin');
      return;
    }
    _onPopState?.call();
  });
}

void clearAdminPopStateHandler() {
  _onPopState = null;
}

/// NTC-01-06 — 새로고침 후에도 현재 CMS 경로 유지
void persistAdminCmsPath(String path) {
  if (path.isEmpty) return;
  html.window.sessionStorage[_kCmsPathKey] = path;
}

String? readPersistedAdminCmsPath() {
  return html.window.sessionStorage[_kCmsPathKey];
}
