import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/main.dart';

void main() {
  testWidgets('Admin app smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RandomChatAdminApp()));
    expect(find.text('관리자 로그인'), findsOneWidget);
  });
}
