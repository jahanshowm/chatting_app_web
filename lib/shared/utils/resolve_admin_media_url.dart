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
    uri = apiBase.replace(path: path, query: '', fragment: '');
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
      return uri
          .replace(
            scheme: apiBase.scheme,
            host: apiBase.host,
            port: apiBase.hasPort ? apiBase.port : null,
          )
          .toString();
    }
    return uri.toString();
  }

  // 프로필·문의 첨부 → 앱 미디어 호스트 /api/...
  if (isPhoto || isInquiryUpload) {
    return mediaBase
        .replace(
          path: '/api$path',
          query: '',
          fragment: '',
        )
        .toString();
  }

  // 어드민 업로드(팝업 등) → 어드민 API /api/...
  return apiBase
      .replace(
        path: '/api$path',
        query: '',
        fragment: '',
      )
      .toString();
}
