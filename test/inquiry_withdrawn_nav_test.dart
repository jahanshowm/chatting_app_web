import 'package:flutter_test/flutter_test.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';

/// INQ-01-02 — 탈퇴 회원 문의 상세에서 사이드바/브레드크럼이 탈퇴 메뉴를 유지하는지
void main() {
  group('AdminMenuSection inquiry detail from query', () {
    final inquirySection = adminMenuSections.firstWhere(
      (s) => s.label == '문의내역',
    );

    test('탈퇴 목록에서 연 상세 → 탈퇴 회원 섹션 매칭', () {
      const path =
          '/inquiries/abc-uuid-1234?from=%2Finquiries%2Fwithdrawn';
      expect(inquirySection.matchesPath(path), isTrue);

      final withdrawn = inquirySection.items.firstWhere(
        (i) => i.path == '/inquiries/withdrawn',
      );
      final active = inquirySection.items.firstWhere(
        (i) => i.path == '/inquiries/active',
      );
      expect(
        AdminMenuSection(
          label: 't',
          items: [withdrawn],
        ).matchesPath(path),
        isTrue,
      );
      expect(
        AdminMenuSection(label: 't', items: [active]).matchesPath(path),
        isFalse,
      );
    });

    test('활동 목록에서 연 상세 → 활동 회원 섹션 매칭', () {
      const path = '/inquiries/abc-uuid-1234?from=%2Finquiries%2Factive';
      expect(
        AdminMenuSection(
          label: 't',
          items: [
            const AdminMenuItem(label: '활동 회원', path: '/inquiries/active'),
          ],
        ).matchesPath(path),
        isTrue,
      );
      expect(
        AdminMenuSection(
          label: 't',
          items: [
            const AdminMenuItem(label: '탈퇴 회원', path: '/inquiries/withdrawn'),
          ],
        ).matchesPath(path),
        isFalse,
      );
    });
  });

  group('adminBreadcrumbForPath', () {
    test('탈퇴 from → 브레드크럼 탈퇴 회원', () {
      final b = adminBreadcrumbForPath(
        '/inquiries/x?from=%2Finquiries%2Fwithdrawn',
      );
      expect(b.section, '문의내역');
      expect(b.item, '탈퇴 회원');
    });

    test('활동 from → 브레드크럼 문의 답변', () {
      final b = adminBreadcrumbForPath(
        '/inquiries/x?from=%2Finquiries%2Factive',
      );
      expect(b.item, '문의 답변');
    });
  });
}
