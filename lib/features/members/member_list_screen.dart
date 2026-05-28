import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_shell.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key, this.initialTab = 'new'});

  final String initialTab;

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  late String _tab = widget.initialTab;
  late DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _end = DateTime.now();
  final _keyword = TextEditingController();
  String _filter = 'all';
  int _page = 1;
  PaginatedResult<Map<String, dynamic>>? _data;
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
            startDate: DateRangeBar.formatApi(_start),
            endDate: DateRangeBar.formatApi(_end),
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
      message: '선택한 ${_selected.length}건을 삭제하시겠습니까?',
    );
    if (ok != true) return;
    await ref.read(adminApiProvider).deleteMembers(tab: _tab, ids: _selected.toList());
    _load();
  }

  List<(String, String)> get _columns {
    switch (_tab) {
      case 'withdrawn':
        return const [
          ('gender', '성별'),
          ('name', '이름'),
          ('payment_summary', '결제'),
          ('inquiry_summary', '문의'),
          ('joined_at', '가입일'),
          ('withdrawn_at', '탈퇴일'),
        ];
      case 'report':
        return const [
          ('gender', '성별'),
          ('reporter_name', '신고자'),
          ('reported_name', '피신고자'),
          ('birth_date', '생년월일'),
          ('phone_number', '연락처'),
          ('reported_at', '신고일'),
        ];
      case 'block':
        return const [
          ('gender', '성별'),
          ('blocker_name', '차단자'),
          ('blocked_name', '피차단자'),
          ('birth_date', '생년월일'),
          ('phone_number', '연락처'),
          ('blocked_at', '차단일'),
        ];
      default:
        return const [
          ('gender', '성별'),
          ('name', '이름'),
          ('birth_date', '생년월일'),
          ('phone_number', '연락처'),
          ('joined_at', '가입일'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _data?.totalPages ?? 1;

    return AdminShell(
      title: '회원관리',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final tab in const [
                  ('new', '신규회원'),
                  ('withdrawn', '탈퇴회원'),
                  ('report', '신고내역'),
                  ('block', '차단내역'),
                ])
                  ChoiceChip(
                    label: Text(tab.$2),
                    selected: _tab == tab.$1,
                    selectedColor: AppColors.secondary,
                    onSelected: (_) {
                      setState(() {
                        _tab = tab.$1;
                        _page = 1;
                      });
                      _load();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DateRangeBar(
              start: _start,
              end: _end,
              onChanged: (s, e) {
                setState(() {
                  _start = s;
                  _end = e;
                  _page = 1;
                });
                _load();
              },
            ),
            const SizedBox(height: 16),
            SearchFilterBar(
              filter: _filter,
              filters: const [
                ('all', '전체'),
                ('name', '이름'),
                ('phone_number', '연락처'),
                ('gender', '성별'),
              ],
              keywordController: _keyword,
              onFilterChanged: (v) => setState(() => _filter = v),
              onSearch: () {
                setState(() => _page = 1);
                _load();
              },
            ),
            const SizedBox(height: 16),
            bulkDeleteBar(selectedCount: _selected.length, onDelete: _deleteSelected),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 900,
                      headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                      columns: [
                        DataColumn2(
                          label: Checkbox(
                            value: _selected.length == (_data?.items.length ?? 0) &&
                                (_data?.items.isNotEmpty ?? false),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.addAll(_data!.items.map((e) => e['id'] as String));
                                } else {
                                  _selected.clear();
                                }
                              });
                            },
                          ),
                          size: ColumnSize.S,
                        ),
                        ..._columns.map((c) => DataColumn2(label: Text(c.$2))),
                        if (_tab == 'new') const DataColumn2(label: Text('상세')),
                      ],
                      rows: (_data?.items ?? []).map((row) {
                        final id = row['id'] as String;
                        return DataRow(
                          selected: _selected.contains(id),
                          onSelectChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(id);
                              } else {
                                _selected.remove(id);
                              }
                            });
                          },
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
                            ..._columns.map((c) => DataCell(Text('${row[c.$1] ?? '-'}'))),
                            if (_tab == 'new')
                              DataCell(
                                TextButton(
                                  onPressed: () => context.go('/members/$id'),
                                  child: const Text('보기'),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
            PaginationBar(
              page: _page,
              totalPages: totalPages,
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
