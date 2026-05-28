import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_shell.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({super.key, required this.userId});

  final String userId;

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
        );
    setState(() => _activities = activities);
  }

  List<(String, String)> get _activityColumns {
    switch (_activityTab) {
      case 'payment':
        return const [
          ('gender', '성별'),
          ('name', '이름'),
          ('phone_number', '연락처'),
          ('product_name', '상품'),
          ('date', '일자'),
        ];
      case 'inquiry':
        return const [
          ('title', '제목'),
          ('date', '일자'),
          ('status', '상태'),
        ];
      default:
        return const [
          ('gender', '성별'),
          ('target_name', '대상'),
          ('birth_date', '생년월일'),
          ('phone_number', '연락처'),
          ('date', '일자'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail?.data ?? {};

    return AdminShell(
      title: '회원 상세',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            _InfoTile(label: '이름', value: '${d['name']}'),
                            _InfoTile(label: '닉네임', value: '${d['nickname']}'),
                            _InfoTile(label: '생년월일', value: '${d['birth_date']}'),
                            _InfoTile(label: '연락처', value: '${d['phone_number']}'),
                            _InfoTile(label: '지역', value: '${d['region']}'),
                            _InfoTile(label: '성별', value: '${d['gender']}'),
                            _InfoTile(label: '가입일', value: '${d['joined_at']}'),
                            _InfoTile(label: '포인트', value: '${d['point']}'),
                            _InfoTile(label: '신고', value: '${d['report_count']}회'),
                            _InfoTile(label: '차단', value: '${d['block_count']}회'),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final url in _detail?.photos ?? [])
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url, width: 96, height: 96, fit: BoxFit.cover),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  sectionTitle('활동내역'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final tab in const [
                        ('report', '신고'),
                        ('block', '차단'),
                        ('payment', '결제'),
                        ('inquiry', '문의'),
                      ])
                        ChoiceChip(
                          label: Text(tab.$2),
                          selected: _activityTab == tab.$1,
                          selectedColor: AppColors.secondary,
                          onSelected: (_) {
                            setState(() {
                              _activityTab = tab.$1;
                              _page = 1;
                            });
                            _loadActivities();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 320,
                    child: DataTable2(
                      columnSpacing: 12,
                      minWidth: 800,
                      headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                      columns: _activityColumns.map((c) => DataColumn2(label: Text(c.$2))).toList(),
                      rows: (_activities?.items ?? []).map((row) {
                        return DataRow(
                          cells: _activityColumns
                              .map((c) => DataCell(Text('${row[c.$1] ?? '-'}')))
                              .toList(),
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
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
