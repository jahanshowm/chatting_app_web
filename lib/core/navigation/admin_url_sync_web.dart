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
