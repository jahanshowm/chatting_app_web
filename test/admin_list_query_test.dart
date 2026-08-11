import 'package:flutter_test/flutter_test.dart';
import 'package:randomchat_admin/shared/utils/admin_list_query.dart';

void main() {
  group('AdminListQuery', () {
    test('날짜·검색을 path 쿼리에 넣고 복원', () {
      final q = AdminListQuery(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 10),
        filter: 'male',
        keyword: '홍길동',
        page: 2,
      );
      final path = q.toPath('/members/new');
      expect(path, contains('start=2026-08-01'));
      expect(path, contains('end=2026-08-10'));
      expect(path, contains('filter=male'));
      expect(path, contains('q=%ED%99%8D%EA%B8%B8%EB%8F%99'));
      expect(path, contains('page=2'));

      final restored = AdminListQuery.fromPath(path);
      expect(restored.sameAs(q), isTrue);
    });

    test('쿼리 없으면 오늘 날짜 기본', () {
      final restored = AdminListQuery.fromPath('/members/withdrawn');
      final today = AdminListQuery.today();
      expect(restored.start, today);
      expect(restored.end, today);
      expect(restored.page, 1);
      expect(restored.period, isNull);
    });

    test('persistDates=false면 start/end를 path에 안 넣음', () {
      final q = AdminListQuery(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 10),
        keyword: '문의',
        page: 2,
        statuses: {'pending'},
        persistDates: false,
      );
      final path = q.toPath('/inquiries/active');
      expect(path, isNot(contains('start=')));
      expect(path, contains('q='));
      expect(path, contains('status=pending'));
      expect(path, contains('page=2'));

      final restored =
          AdminListQuery.fromPath(path, persistDates: false);
      expect(restored.keyword, '문의');
      expect(restored.page, 2);
      expect(restored.statuses, {'pending'});
    });

    test('status all과 null은 sameAs', () {
      final a = AdminListQuery(
        start: AdminListQuery.today(),
        end: AdminListQuery.today(),
        statuses: {'all'},
        persistDates: false,
      );
      final b = AdminListQuery(
        start: AdminListQuery.today(),
        end: AdminListQuery.today(),
        persistDates: false,
      );
      expect(a.sameAs(b), isTrue);
    });

    test('defaultPeriod는 결제/대시보드 복원용', () {
      final restored = AdminListQuery.fromPath(
        '/payments?start=2026-08-01&end=2026-08-01',
        defaultPeriod: 'daily',
      );
      expect(restored.period, 'daily');
    });

    test('content key는 path만 (쿼리 무시)', () {
      expect(
        adminContentKeyForPath('/members/new?start=2026-08-01&end=2026-08-01'),
        '/members/new',
      );
    });
  });
}
