import 'package:flutter_test/flutter_test.dart';

/// NTC-01-01 — 문의 상세: 회원정보 헤더 높이 상한 → 채팅 영역 비중 확보
void main() {
  test('header max height is 30% clamped 140–260', () {
    double headerMax(double maxHeight) =>
        (maxHeight * 0.30).clamp(140.0, 260.0);

    // 일반적인 어드민 콘텐츠 높이
    expect(headerMax(800), 240.0);
    expect(headerMax(900), 260.0); // clamp upper
    expect(headerMax(400), 140.0); // clamp lower (400*0.3=120 → 140)

    // 헤더가 전체의 절반을 넘지 않음
    final h = headerMax(700);
    expect(h / 700, lessThan(0.4));
    expect(700 - h, greaterThan(h)); // 채팅(+기타) 쪽이 더 큼
  });
}
