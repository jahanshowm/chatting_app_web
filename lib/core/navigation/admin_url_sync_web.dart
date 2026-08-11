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

void ensureAdminPopStateInstalled(void Function() onPop) {
  if (_popStateInstalled) return;
  _popStateInstalled = true;
  html.window.onPopState.listen((_) => onPop());
}

/// NTC-01-06 — 새로고침 후에도 현재 CMS 경로 유지
void persistAdminCmsPath(String path) {
  if (path.isEmpty) return;
  html.window.sessionStorage[_kCmsPathKey] = path;
}

String? readPersistedAdminCmsPath() {
  return html.window.sessionStorage[_kCmsPathKey];
}
