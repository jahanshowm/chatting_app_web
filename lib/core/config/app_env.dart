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
}
