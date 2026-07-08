import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/navigation/admin_screen_specs.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';

class MemberReportBlockScreen extends ConsumerStatefulWidget {
  const MemberReportBlockScreen({super.key, this.initialTab = 'report'});

  final String initialTab;

  @override
  ConsumerState<MemberReportBlockScreen> createState() => _MemberReportBlockScreenState();
}

class _MemberReportBlockScreenState extends ConsumerState<MemberReportBlockScreen> {
  late String _tab = widget.initialTab == 'block' ? 'block' : 'report';
  final _keyword = TextEditingController();
  String _filter = 'all';
  int _page = 1;
  PaginatedResult<Map<String, dynamic>>? _data;
  final Set<String> _selected = {};
  bool _loading = true;

  AdminScreenSpec get _spec => _tab == 'block' ? memberBlockSpec : memberReportSpec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MemberReportBlockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tab = widget.initialTab == 'block' ? 'block' : 'report';
      _filter = 'all';
      _page = 1;
      _keyword.clear();
      _load();
    }
  }

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(adminApiProvider).members(
            tab: _tab,
            page: _page,
            filter: _filter,
            keyword: _keyword.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _data = data;
        _selected.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showConfirmDialog(
      context,
      title: '삭제 확인',
      message: '선택한 ${_selected.length}개의 항목을 삭제하시겠습니까?',
    );
    if (ok != true) return;
    await ref.read(adminApiProvider).deleteMembers(tab: _tab, ids: _selected.toList());
    _load();
  }

  List<(String, String)> get _columns {
    if (_tab == 'block') {
      return const [
        ('gender', '성별'),
        ('blocker_name', '차단자'),
        ('blocked_name', '차단대상'),
        ('birth_date', '생년월일'),
        ('phone_number', '휴대폰번호'),
        ('blocked_at', '차단일'),
      ];
    }
    return const [
      ('gender', '성별'),
      ('reporter_name', '신고자'),
      ('reported_name', '신고대상'),
      ('birth_date', '생년월일'),
      ('phone_number', '휴대폰번호'),
      ('reported_at', '신고일'),
    ];
  }

  void _openMemberDetail(Map<String, dynamic> row) {
    final userId = (_tab == 'block'
            ? row['blocker_user_id']
            : row['reporter_user_id'])
        ?.toString();
    if (userId == null || userId.isEmpty) return;
    adminNavigateReplace(
      ref,
      '/members/$userId?from=${Uri.encodeComponent('/members/report-block')}',
    );
  }

  void _resetSearch() {
    setState(() {
      _filter = 'all';
      _page = 1;
      _keyword.clear();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final items = _data?.items ?? [];
    final totalPages = _data?.totalPages ?? 1;
    final totalCount = _data?.total ?? items.length;

    return AdminContentArea(
      screenId: spec.id,
      subtitle: spec.subtitle,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTabBar(
            tabs: const [('report', '신고'), ('block', '차단')],
            selected: _tab,
            onSelected: (tab) {
              setState(() {
                _tab = tab;
                _filter = 'all';
                _page = 1;
                _keyword.clear();
              });
              _load();
            },
          ),
          if (_tab == 'block')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '대화방 차단회원',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),
          SearchFilterBar(
            filter: _filter,
            filters: spec.filters,
            keywordController: _keyword,
            hint: spec.searchHint,
            useSearchIcon: _tab == 'block',
            onFilterChanged: (v) => setState(() => _filter = v),
            onSearch: () {
              setState(() => _page = 1);
              _load();
            },
            onReset: _resetSearch,
          ),
        ],
      ),
      summary: Row(
        children: [
          const Spacer(),
          DeleteActionButton(selectedCount: _selected.length, onDelete: _deleteSelected),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : AdminListPanel(
              child: items.isEmpty
                  ? const SizedBox(
                      height: 240,
                      child: Center(child: AdminEmptyList()),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 960,
                            headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                            columns: [
                              DataColumn2(
                                label: Checkbox(
                                  value: _selected.length == items.length && items.isNotEmpty,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selected.addAll(items.map((e) => e['id'] as String));
                                      } else {
                                        _selected.clear();
                                      }
                                    });
                                  },
                                ),
                                size: ColumnSize.S,
                              ),
                              ..._columns.map((c) => DataColumn2(label: Text(c.$2))),
                            ],
                            rows: items.map((row) {
                              final id = row['id'] as String;
                              return DataRow2(
                                onTap: () => _openMemberDetail(row),
                                cells: [
                                  DataCell(Checkbox(
                                    value: _selected.contains(id),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selected.add(id);
                                        } else {
                                          _selected.remove(id);
                                        }
                                      });
                                    },
                                  )),
                                  ..._columns.map((c) {
                                    if (c.$1 == 'gender') {
                                      return DataCell(GenderCellText('${row[c.$1] ?? '-'}'));
                                    }
                                    return DataCell(Text('${row[c.$1] ?? '-'}'));
                                  }),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        ListPageFooter(
                          page: _page,
                          totalPages: totalPages,
                          totalCount: totalCount,
                          onPageChanged: (p) {
                            setState(() => _page = p);
                            _load();
                          },
                        ),
                      ],
                    ),
            ),
    );
  }
}
