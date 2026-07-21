// Web 전용 URL sync (조건부 import). dart:html 사용이 의도됨.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

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

bool _popStateInstalled = false;

void ensureAdminPopStateInstalled(void Function() onPop) {
  if (_popStateInstalled) return;
  _popStateInstalled = true;
  html.window.onPopState.listen((_) => onPop());
}
