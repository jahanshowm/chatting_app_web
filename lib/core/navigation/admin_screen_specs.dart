/// 엑셀/피그마 화면별 메타 (필터·컬럼·화면 ID)
class AdminScreenSpec {
  const AdminScreenSpec({
    required this.id,
    required this.subtitle,
    required this.filters,
    this.showDateRange = true,
    this.showPeriod = false,
    this.searchHint = '검색어를 입력하세요',
  });

  final String id;
  final String subtitle;
  final List<(String, String)> filters;
  final bool showDateRange;
  final bool showPeriod;
  final String searchHint;
}

const memberNewSpec = AdminScreenSpec(
  id: 'CMS-01-01',
  subtitle: '가입일 기준 최신순 · 10건씩 노출',
  filters: [
    ('all', '전체'),
    ('gender', '성별'),
    ('name', '이름'),
    ('birth_date', '생년월일'),
    ('phone_number', '휴대폰번호'),
    ('joined_at', '가입일'),
  ],
);

const memberWithdrawnSpec = AdminScreenSpec(
  id: 'CMS-01-03',
  subtitle: '탈퇴 회원 · 결제/문의 내역 확인',
  filters: [
    ('all', '전체'),
    ('gender', '성별'),
    ('payment_summary', '결제내역'),
    ('inquiry_summary', '문의내역'),
    ('joined_at', '가입일'),
    ('withdrawn_at', '탈퇴일'),
  ],
);

const memberReportSpec = AdminScreenSpec(
  id: 'CMS-01-04',
  subtitle: '신고 내역 · 신고자 기준 정보 노출',
  showDateRange: false,
  filters: [
    ('all', '전체'),
    ('reporter', '신고자'),
    ('reported', '신고대상'),
  ],
  searchHint: '이름 검색',
);

const memberBlockSpec = AdminScreenSpec(
  id: 'CMS-01-05',
  subtitle: '대화방 차단 내역 · 차단자 기준 정보 노출',
  showDateRange: false,
  filters: [
    ('all', '전체'),
    ('blocker', '차단자'),
    ('blocked', '차단대상'),
  ],
  searchHint: '이름 검색',
);

const paymentSpec = AdminScreenSpec(
  id: 'PG-01',
  subtitle: '결제완료 일시 기준 최신순 · 10건씩 노출',
  showPeriod: true,
  filters: [
    ('all', '전체'),
    ('gender', '성별'),
    ('name', '이름'),
    ('phone_number', '휴대폰번호'),
    ('product_name', '상품명'),
  ],
);

const inquiryActiveSpec = AdminScreenSpec(
  id: 'INQ-01',
  subtitle: '활동 회원 문의 · 처리상태 필터',
  showDateRange: false,
  searchHint: '이름 또는 문의제목 검색',
  filters: [],
);

const inquiryWithdrawnSpec = AdminScreenSpec(
  id: 'INQ-01-02',
  subtitle: '탈퇴 회원 문의 · 처리상태 필터',
  showDateRange: false,
  searchHint: '이름 또는 문의제목 검색',
  filters: [],
);

const popupListSpec = AdminScreenSpec(
  id: 'NTC-01',
  subtitle: '팝업 목록 관리',
  showDateRange: false,
  filters: [],
);

const popupFormSpec = AdminScreenSpec(
  id: 'NTC-01-01',
  subtitle: '팝업 등록 및 수정',
  showDateRange: false,
  filters: [],
);

const fcmListSpec = AdminScreenSpec(
  id: 'NTC-01-02',
  subtitle: 'FCM 발송 이력',
  showDateRange: true,
  filters: [],
  searchHint: '제목 검색',
);

const fcmSendTypeSpec = AdminScreenSpec(
  id: 'NTC-01-03',
  subtitle: '발송 타겟 및 방식 설정',
  showDateRange: false,
  filters: [],
);

const fcmAllSendSpec = AdminScreenSpec(
  id: 'NTC-01-04',
  subtitle: 'FCM 전체발송',
  showDateRange: false,
  filters: [],
);

const fcmTargetSendSpec = AdminScreenSpec(
  id: 'NTC-01-05',
  subtitle: 'FCM 타겟발송',
  showDateRange: false,
  filters: [],
);

const noticeSpec = AdminScreenSpec(
  id: 'NTC-01-06',
  subtitle: '공지사항 목록',
  showDateRange: false,
  filters: [
    ('all', '전체'),
    ('title', '제목'),
    ('view_count', '조회수'),
    ('date', '일자'),
    ('manage', '관리'),
  ],
  searchHint: '검색어를 입력하세요',
);

const noticeFormSpec = AdminScreenSpec(
  id: 'NTC-01-07',
  subtitle: '공지사항 등록 및 수정',
  showDateRange: false,
  filters: [],
);
