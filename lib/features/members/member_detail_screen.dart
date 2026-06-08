import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/navigation/admin_screen_specs.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_detail_back_bar.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';
import 'package:randomchat_admin/shared/widgets/member_info_header.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({
    super.key,
    required this.userId,
    this.listPath = '/members/new',
  });

  final String userId;
  final String listPath;

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  MemberDetail? _detail;
  String _activityTab = 'report';
  PaginatedResult<Map<String, dynamic>>? _activities;
  int _page = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ref.read(adminApiProvider);
    try {
      final detail = await api.memberDetail(widget.userId);
      final activities = await api.memberActivities(
        userId: widget.userId,
        tab: _activityTab,
        page: _page,
        limit: 5,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _activities = activities;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadActivities() async {
    final activities = await ref.read(adminApiProvider).memberActivities(
          userId: widget.userId,
          tab: _activityTab,
          page: _page,
          limit: 5,
        );
    setState(() => _activities = activities);
  }

  List<(String, String)> get _activityColumns {
    switch (_activityTab) {
      case 'payment':
        return const [
          ('gender', '성별'),
          ('name', '이름'),
          ('phone_number', '휴대폰번호'),
          ('product_name', '상품명'),
          ('date', '결제일'),
        ];
      case 'inquiry':
        return const [
          ('gender', '성별'),
          ('name', '이름'),
          ('title', '문의제목'),
          ('date', '일자'),
          ('status', '처리상태'),
        ];
      case 'block':
        return const [
          ('gender', '성별'),
          ('target_name', '차단대상'),
          ('birth_date', '생년월일'),
          ('phone_number', '휴대폰번호'),
          ('date', '차단일'),
        ];
      default:
        return const [
          ('gender', '성별'),
          ('target_name', '신고대상'),
          ('birth_date', '생년월일'),
          ('phone_number', '휴대폰번호'),
          ('date', '신고일'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final activityItems = _activities?.items ?? [];

    return AdminContentArea(
      screenId: memberDetailSpec.id,
      subtitle: memberDetailSpec.subtitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminDetailBackBar(backPath: widget.listPath),
            MemberInfoHeader(
              data: _detail?.data ?? {},
              photos: _detail?.photos ?? [],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: sectionTitle('활동내역')),
                AdminChipTabBar(
                  tabs: const [
                    ('report', '신고'),
                    ('block', '차단'),
                    ('payment', '결제내역'),
                    ('inquiry', '문의내역'),
                  ],
                  selected: _activityTab,
                  onSelected: (tab) {
                    setState(() {
                      _activityTab = tab;
                      _page = 1;
                    });
                    _loadActivities();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminListPanel(
              child: activityItems.isEmpty
                  ? const SizedBox(
                      height: 240,
                      child: Center(
                        child: AdminEmptyList(message: '활동 내역이 없습니다.'),
                      ),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 320,
                          child: DataTable2(
                            columnSpacing: 12,
                            minWidth: 800,
                            headingRowColor: WidgetStateProperty.all(AppColors.inputBg),
                            columns: _activityColumns
                                .map((c) => DataColumn2(label: Text(c.$2)))
                                .toList(),
                            rows: activityItems.map((row) {
                              final inquiryId = row['id']?.toString();
                              return DataRow2(
                                onTap: _activityTab == 'inquiry' && inquiryId != null
                                    ? () => adminNavigateReplace(
                                          ref,
                                          '/inquiries/$inquiryId?from=${Uri.encodeComponent(widget.listPath)}',
                                        )
                                    : null,
                                cells: _activityColumns.map((c) {
                                  if (c.$1 == 'gender') {
                                    return DataCell(GenderCellText('${row[c.$1] ?? '-'}'));
                                  }
                                  return DataCell(Text('${row[c.$1] ?? '-'}'));
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ),
                        PaginationBar(
                          page: _page,
                          totalPages: _activities?.totalPages ?? 1,
                          onPageChanged: (p) {
                            setState(() => _page = p);
                            _loadActivities();
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
