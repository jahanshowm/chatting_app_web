import 'package:randomchat_admin/core/config/app_env.dart';

/// 어드민 Web(Flutter)용 미디어 URL 교정.
///
/// 운영에서 DB/API가 `https://randomchat.kr/photos/...` 를 주면 Apache 정적
/// `/photos`에는 CORS가 없어 Image.network가 실패한다.
/// `/api/photos`·`/api/uploads` 로 바꿔 앱 API(CORS 허용)에서 받게 한다.
String resolveAdminMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  final apiBase = Uri.parse(AppEnv.apiBaseUrl);
  final mediaBase = Uri.parse(AppEnv.mediaBaseUrl);

  late Uri uri;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    final path = url.startsWith('/') ? url : '/$url';
    uri = _originUri(apiBase, path);
  } else {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;
    uri = parsed;
  }

  const legacyHosts = {'127.0.0.1', 'localhost', '10.0.2.2'};
  final host = uri.host;
  final isLegacy = legacyHosts.contains(host) || host.startsWith('192.168.');

  var path = uri.path;
  if (path.startsWith('/api/photos/') || path.startsWith('/api/uploads/')) {
    path = path.substring('/api'.length);
  }

  final isPhoto = path.startsWith('/photos/');
  final isInquiryUpload = path.startsWith('/uploads/inquiries/');
  final isAdminUpload = path.startsWith('/uploads/');

  if (!isPhoto && !isAdminUpload) {
    if (isLegacy) {
      return _originUri(apiBase, uri.path).toString();
    }
    return uri.toString();
  }

  // 프로필·문의 첨부 → 앱 미디어 호스트 /api/...
  if (isPhoto || isInquiryUpload) {
    return _originUri(mediaBase, '/api$path').toString();
  }

  // 팝업 등 — DB가 앱 미디어 호스트면 유지(공유 디스크), 아니면 어드민 API
  final origin = uri.host == mediaBase.host ? mediaBase : apiBase;
  return _originUri(origin, '/api$path').toString();
}

Uri _originUri(Uri base, String path) {
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: path,
  );
}
