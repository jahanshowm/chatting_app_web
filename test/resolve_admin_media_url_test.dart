import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randomchat_admin/shared/utils/resolve_admin_media_url.dart';

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: '''
API_BASE_URL=https://adminchat.kr
MEDIA_BASE_URL=https://randomchat.kr
''');
  });

  test('프로필 /photos → 앱 /api/photos', () {
    expect(
      resolveAdminMediaUrl('https://randomchat.kr/photos/u1/0.jpg'),
      'https://randomchat.kr/api/photos/u1/0.jpg',
    );
  });

  test('팝업 URL이 앱 호스트면 유지', () {
    expect(
      resolveAdminMediaUrl(
        'https://randomchat.kr/api/uploads/admin/abc.png',
      ),
      'https://randomchat.kr/api/uploads/admin/abc.png',
    );
  });

  test('팝업 URL이 어드민 호스트면 어드민 API', () {
    expect(
      resolveAdminMediaUrl(
        'https://adminchat.kr/api/uploads/admin/abc.png',
      ),
      'https://adminchat.kr/api/uploads/admin/abc.png',
    );
  });
}
