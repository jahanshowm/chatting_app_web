import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randomchat_admin/core/navigation/admin_shell_path_provider.dart';

/// 브라우저(크롬) 뒤로가기 = handleBrowserBack / navigateBackOr(canPop)
void main() {
  group('browser back stack', () {
    test('회원상세 → 상대상세 → back → 이전 회원상세', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);

      nav.resetTo('/members/a?from=%2Fmembers%2Fnew');
      nav.setPath('/members/b?from=%2Fmembers%2Fa');
      expect(container.read(adminShellPathProvider), contains('/members/b'));

      nav.handleBrowserBack();
      expect(container.read(adminShellPathProvider), contains('/members/a'));
    });

    test('목록 → 폼 → back → 목록', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);

      nav.resetTo('/operations/popups');
      nav.setPath('/operations/popups/new');
      nav.handleBrowserBack();
      expect(container.read(adminShellPathProvider), '/operations/popups');
    });

    test('탈퇴 → 결제 → back → 탈퇴', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);

      nav.resetTo('/members/withdrawn');
      nav.setPath(
        '/payments?user_id=u1&from=${Uri.encodeComponent('/members/withdrawn')}',
      );
      nav.handleBrowserBack();
      expect(container.read(adminShellPathProvider), '/members/withdrawn');
    });

    test('사이드바 연속 이동 후 back으로 역순 복귀', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);

      nav.resetTo('/dashboard');
      nav.setPath('/members/new');
      nav.setPath('/inquiries/active');
      nav.setPath('/operations/notices');

      nav.handleBrowserBack();
      expect(container.read(adminShellPathProvider), '/inquiries/active');
      nav.handleBrowserBack();
      expect(container.read(adminShellPathProvider), '/members/new');
      nav.handleBrowserBack();
      expect(container.read(adminShellPathProvider), '/dashboard');
    });

    test('navigateBackOr: 스택 있으면 pop (fallback 불일치여도)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);

      nav.resetTo('/members/a');
      nav.setPath('/members/b');
      nav.navigateBackOr('/members/new'); // fallback 달라도 canPop이면 pop
      expect(container.read(adminShellPathProvider), '/members/a');
    });

    test('navigateBackOr: 스택 1이면 fallback replace', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);

      nav.resetTo('/operations/popups/new');
      nav.navigateBackOr('/operations/popups');
      expect(container.read(adminShellPathProvider), '/operations/popups');
    });

    test('필터 쿼리 있는 목록 → 상세 → back → 필터 유지', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);

      const list =
          '/members/withdrawn?start=2026-08-01&end=2026-08-10&filter=male&q=test&page=2';
      nav.resetTo(list);
      nav.setPath(
        '/members/u1?from=${Uri.encodeComponent(list)}',
      );
      nav.handleBrowserBack();
      expect(container.read(adminShellPathProvider), list);
    });

    test('navigateBackOr fallback에 필터 쿼리 포함', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);

      const list =
          '/members/new?start=2026-07-01&end=2026-07-31&q=kim';
      nav.resetTo('/members/u1?from=${Uri.encodeComponent(list)}');
      nav.navigateBackOr(list);
      expect(container.read(adminShellPathProvider), list);
    });

    test('필터 replace 후 push → back 시 replace된 필터 복원', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);

      nav.resetTo('/members/new');
      nav.setPathReplace(
        '/members/new?start=2026-08-05&end=2026-08-05',
      );
      nav.setPath('/members/u1?from=%2Fmembers%2Fnew');
      nav.handleBrowserBack();
      expect(
        container.read(adminShellPathProvider),
        '/members/new?start=2026-08-05&end=2026-08-05',
      );
    });
  });
}
