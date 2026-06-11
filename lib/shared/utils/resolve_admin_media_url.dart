import 'package:randomchat_admin/core/config/app_env.dart';

/// 관리자 CMS에서 업로드·API 이미지 URL 정규화
///
/// DB에 `http://192.168.x.x:3000/photos/...` 등으로 저장된 URL을
/// 현재 어드민 `API_BASE_URL` 호스트로 맞춤 (Flutter Web CORS·접근 불가 방지).
String resolveAdminMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  final base = Uri.parse(AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), ''));

  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    if (url.startsWith('/')) return '$base$url';
    return '$base/$url';
  }

  final uri = Uri.tryParse(url);
  if (uri == null) return url;

  final sameOrigin = uri.scheme == base.scheme &&
      uri.host == base.host &&
      uri.port == base.port;

  if ((uri.path.contains('/photos/') || uri.path.contains('/uploads/')) &&
      !sameOrigin) {
    return uri
        .replace(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
        )
        .toString();
  }

  const legacyHosts = {'127.0.0.1', 'localhost', '10.0.2.2'};
  if (legacyHosts.contains(uri.host) && !sameOrigin) {
    return uri
        .replace(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
        )
        .toString();
  }

  return url;
}
