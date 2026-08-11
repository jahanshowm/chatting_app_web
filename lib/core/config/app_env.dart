import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env', isOptional: true);
  }

  static String get apiBaseUrl {
    final raw = dotenv.env['API_BASE_URL']?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'http://localhost:3000';
  }

  /// 프로필 사진·앱 업로드 미디어 호스트 (운영: randomchat.kr).
  /// 미설정 시 [apiBaseUrl]과 동일 (로컬·QA 단일 API).
  static String get mediaBaseUrl {
    final raw = dotenv.env['MEDIA_BASE_URL']?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return apiBaseUrl;
  }
}
