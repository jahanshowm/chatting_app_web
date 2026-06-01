import 'package:randomchat_admin/core/config/app_env.dart';

/// 관리자 CMS에서 업로드·API 이미지 URL 정규화
String resolveAdminMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (url.startsWith('/')) return '$base$url';
  return '$base/$url';
}
