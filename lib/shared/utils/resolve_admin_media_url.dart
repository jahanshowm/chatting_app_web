import 'package:randomchat_admin/core/config/app_env.dart';

/// API가 내려준 URL은 그대로 사용. localhost·사설 IP만 apiBaseUrl로 교정.
String resolveAdminMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    final base = Uri.parse(AppEnv.apiBaseUrl);
    if (url.startsWith('/')) return '$base$url';
    return '$base/$url';
  }

  final uri = Uri.tryParse(url);
  if (uri == null) return url;

  const legacyHosts = {'127.0.0.1', 'localhost', '10.0.2.2', '192.168.'};
  final isLegacy = legacyHosts.any(
    (h) => uri.host == h || (h.endsWith('.') && uri.host.startsWith(h)),
  );
  if (!isLegacy) return url;

  final base = Uri.parse(AppEnv.apiBaseUrl);
  return uri
      .replace(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
      )
      .toString();
}
