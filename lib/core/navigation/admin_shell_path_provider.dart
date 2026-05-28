import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_url_sync.dart';

class AdminShellPathNotifier extends Notifier<String> {
  @override
  String build() => '/dashboard';

  void setPath(String path, {bool syncBrowserUrl = false}) {
    if (path.isEmpty || state == path) return;
    state = path;
    // CMS 내부 이동 시 URL을 바꾸면 go_router가 미등록 경로로 감지해 redirect → history 쌓임
    if (syncBrowserUrl) {
      replaceAdminBrowserUrl(path);
    }
  }

  void resetTo(String path) {
    state = path;
    resetAdminBrowserHistory(path);
  }
}

final adminShellPathProvider =
    NotifierProvider<AdminShellPathNotifier, String>(AdminShellPathNotifier.new);
