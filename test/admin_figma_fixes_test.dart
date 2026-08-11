import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randomchat_admin/core/navigation/admin_shell_path_provider.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';

/// 피그마 관리자페이지(수정사항) — 로직 단위 검증
void main() {
  group('DAS-01 DateRangeBar', () {
    test('시작 > 종료면 무효', () {
      final start = DateTime(2026, 8, 5);
      final end = DateTime(2026, 8, 3);
      expect(DateRangeBar.isValidRange(start, end), isFalse);
    });

    test('같은 날·시작≤종료는 유효', () {
      final d = DateTime(2026, 8, 3);
      expect(DateRangeBar.isValidRange(d, d), isTrue);
      expect(
        DateRangeBar.isValidRange(DateTime(2026, 8, 1), DateTime(2026, 8, 3)),
        isTrue,
      );
    });

    test('API 날짜는 YYYY-MM-DD', () {
      expect(DateRangeBar.formatApi(DateTime(2026, 8, 3)), '2026-08-03');
    });
  });

  group('CMS-02 / NTC navigateBackOr', () {
    test('스택 있으면 pop (브라우저 뒤로가기와 동일)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);
      nav.resetTo('/members/a');
      nav.setPath('/members/b');
      expect(container.read(adminShellPathProvider), '/members/b');

      nav.navigateBackOr('/members/a');
      expect(container.read(adminShellPathProvider), '/members/a');
    });

    test('스택 1이면 fallback replace', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final nav = container.read(adminShellPathProvider.notifier);
      nav.resetTo('/dashboard');
      nav.setPathReplace('/operations/popups/new');

      nav.navigateBackOr('/operations/popups');
      expect(container.read(adminShellPathProvider), '/operations/popups');
    });
  });
}
