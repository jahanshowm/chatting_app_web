import 'dart:html' as html;

void replaceAdminBrowserUrl(String path) {
  html.window.history.replaceState(null, '', path);
}

void resetAdminBrowserHistory(String path) {
  html.window.history.replaceState(null, '', path);
}
