/// MEM — 신규/탈퇴 회원 목록·검색·필터
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/navigation/admin_screen_specs.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/utils/admin_list_query.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({
    super.key,
    required this.tab,
    required this.routePath,
  });

  /// new | withdrawn
  final String tab;
  /// CMS path (+ 날짜·검색 쿼리) — 뒤로가기 복원용
  final String routePath;

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  late String _tab = widget.tab;
  late DateTime _start;
  late DateTime _end;
  final _keyword = TextEditingController();
  late String _filter;
  late int _page;
  PaginatedResult<Map<String, dynamic>>? _data;
  final Set<String> _selected = {};
  bool _loading = true;

  AdminScreenSpec get _spec => _tab == 'withdrawn' ? memberWithdrawnSpec : memberNewSpec;

  String get _basePath => _tab == 'withdrawn' ? '/members/withdrawn' : '/members/new';

  AdminListQuery get _query => AdminListQuery(
        start: _start,
        end: _end,
        filter: _filter,
        keyword: _keyword.text,
        page: _page,
      );

  String get _listPathWithQuery => _query.toPath(_basePath);

  @override
  void initState() {
    super.initState();
    _applyQuery(AdminListQuery.fromPath(widget.routePath), syncPath: false);
    _load();
  }

  @override
  void didUpdateWidget(MemberListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) {
      _tab = widget.tab;
      _applyQuery(AdminListQuery.fromPath(widget.routePath), syncPath: false);
      _selected.clear();
      _load();
      return;
    }
    if (oldWidget.routePath != widget.routePath) {
      final incoming = AdminListQuery.fromPath(widget.routePath);
      if (!incoming.sameAs(_query)) {
        _applyQuery(incoming, syncPath: false);
        _load();
      }
    }
  }

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  void _applyQuery(AdminListQuery q, {required bool syncPath}) {
    _start = q.start;
    _end = q.end;
    _filter = q.filter;
    _page = q.page;
    if (_keyword.text != q.keyword) {
      _keyword.text = q.keyword;
    }
    if (syncPath) {
      syncAdminListPath(ref, _basePath, _query);
    }
  }

  void _persistAndLoad({bool resetPage = false}) {
    if (resetPage) _page = 1;
    syncAdminListPath(ref, _basePath, _query);
    _load();
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
      message: '선택한 ${_selected.length}개의 항목을 삭제하시겠습니까?',
    );
    if (ok != true) return;
    await ref.read(adminApiProvider).deleteMembers(tab: _tab, ids: _selected.toList());
    _load();
  }

  void _resetSearch() {
    final d = AdminListQuery.today();
    setState(() {
      _start = d;
      _end = d;
      _filter = 'all';
      _page = 1;
      _keyword.clear();
    });
    _persistAndLoad();
  }

  List<(String, String)> get _columns {
    if (_tab == 'withdrawn') {
      return const [
        ('gender', '성별'),
        ('payment_summary', '결제내역'),
        ('inquiry_summary', '문의내역'),
        ('joined_at', '가입일'),
        ('withdrawn_at', '탈퇴일'),
      ];
    }
    return [
      ('gender', '성별'),
      ('name', '이름'),
      ('birth_date', '생년월일'),
      ('phone_number', '휴대폰번호'),
      ('account_type', '구분'),
      ('joined_at', '가입일'),
    ];
  }

  // TODO: 휴대폰번호 변경 UI 임시 비활성 — 재활성 시 가입일 셀 주석도 함께 해제
  // Future<void> _changePhone(Map<String, dynamic> row) async {
  //   final id = row['id'] as String?;
  //   if (id == null || id.isEmpty) return;
  //   final current = '${row['phone_number'] ?? ''}'.replaceAll('-', '');
  //   final controller = TextEditingController(
  //     text: current == '-' ? '' : current,
  //   );
  //   final ok = await showDialog<bool>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: const Text('휴대폰번호 변경'),
  //       content: TextField(
  //         controller: controller,
  //         keyboardType: TextInputType.phone,
  //         autofocus: true,
  //         decoration: const InputDecoration(
  //           hintText: '숫자만 입력',
  //           labelText: '새 휴대폰번호',
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx, false),
  //           child: const Text('취소'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(ctx, true),
  //           child: const Text('변경'),
  //         ),
  //       ],
  //     ),
  //   );
  //   final digits = controller.text.replaceAll(RegExp(r'\D'), '');
  //   controller.dispose();
  //   if (ok != true || !mounted) return;
  //   if (digits.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('휴대폰번호를 입력해주세요.')),
  //     );
  //     return;
  //   }
  //   try {
  //     await ref.read(adminApiProvider).updateMemberPhone(
  //           userId: id,
  //           phoneNumber: digits,
  //         );
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('휴대폰번호가 변경되었습니다.')),
  //     );
  //     await _load();
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.toString())),
  //     );
  //   }
  // }

  void _openDetail(String id) {
    adminNavigate(
      ref,
      '/members/$id?from=${Uri.encodeComponent(_listPathWithQuery)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final items = _data?.items ?? [];
    final totalPages = _data?.totalPages ?? 1;
    final totalCount = _data?.total ?? items.length;
    final returnTo = _listPathWithQuery;

    return AdminContentArea(
      screenId: spec.id,
      subtitle: spec.subtitle,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateRangeBar(
            start: _start,
            end: _end,
            onChanged: (s, e) {
              setState(() {
                _start = s;
                _end = e;
              });
              _persistAndLoad(resetPage: true);
            },
          ),
          const SizedBox(height: 16),
          SearchFilterBar(
            filter: _filter,
            filters: spec.filters,
            keywordController: _keyword,
            hint: spec.searchHint,
            onFilterChanged: (v) => setState(() => _filter = v),
            onSearch: () {
              setState(() {});
              _persistAndLoad(resetPage: true);
            },
            onReset: _resetSearch,
          ),
        ],
      ),
      summary: _tab == 'withdrawn'
          ? null
          : Row(
              children: [
                const Spacer(),
                DeleteActionButton(
                  selectedCount: _selected.length,
                  onDelete: _deleteSelected,
                ),
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
                            headingRowColor:
                                WidgetStateProperty.all(AppColors.inputBg),
                            columns: [
                              if (_tab != 'withdrawn')
                                DataColumn2(
                                  label: Checkbox(
                                    value: _selected.length == items.length &&
                                        items.isNotEmpty,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selected.addAll(
                                            items.map((e) => e['id'] as String),
                                          );
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
                                onTap: _tab == 'withdrawn'
                                    ? null
                                    : () => _openDetail(id),
                                selected: _selected.contains(id),
                                cells: [
                                  if (_tab != 'withdrawn')
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
                                    if (_tab == 'withdrawn' &&
                                        c.$1 == 'inquiry_summary') {
                                      final count = row[c.$1];
                                      return DataCell(
                                        TextButton(
                                          onPressed: () => adminNavigate(
                                            ref,
                                            '/inquiries/withdrawn?user_id=${Uri.encodeComponent(id)}&from=${Uri.encodeComponent(returnTo)}',
                                          ),
                                          child: Text(
                                            count == '-'
                                                ? '내역보기'
                                                : '내역보기 ($count)',
                                          ),
                                        ),
                                      );
                                    }
                                    if (_tab == 'withdrawn' &&
                                        c.$1 == 'payment_summary') {
                                      final count = row[c.$1];
                                      return DataCell(
                                        TextButton(
                                          onPressed: () => adminNavigate(
                                            ref,
                                            '/payments?user_id=${Uri.encodeComponent(id)}&from=${Uri.encodeComponent(returnTo)}',
                                          ),
                                          child: Text(
                                            count == '-'
                                                ? '내역보기'
                                                : '내역보기 ($count)',
                                          ),
                                        ),
                                      );
                                    }
                                    if (c.$1 == 'gender') {
                                      return DataCell(
                                        GenderCellText('${row[c.$1] ?? '-'}'),
                                      );
                                    }
                                    if (c.$1 == 'account_type') {
                                      final fake = row['is_real'] == false ||
                                          row['account_type'] == '가짜';
                                      return DataCell(
                                        Text(
                                          fake ? '가짜' : '실제',
                                          style: TextStyle(
                                            color: fake
                                                ? const Color(0xFFB45309)
                                                : null,
                                            fontWeight: fake
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      );
                                    }
                                    // TODO: 휴대폰번호 변경 UI 임시 비활성
                                    // if (_tab != 'withdrawn' &&
                                    //     c.$1 == 'joined_at') {
                                    //   return DataCell(
                                    //     Row(
                                    //       children: [
                                    //         Flexible(
                                    //           child: Text(
                                    //             '${row[c.$1] ?? '-'}',
                                    //           ),
                                    //         ),
                                    //         const SizedBox(width: 8),
                                    //         TextButton(
                                    //           onPressed: () =>
                                    //               _changePhone(row),
                                    //           child: const Text('번호변경'),
                                    //         ),
                                    //       ],
                                    //     ),
                                    //     onTap: () => _changePhone(row),
                                    //   );
                                    // }
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
                            _persistAndLoad();
                          },
                        ),
                      ],
                    ),
            ),
    );
  }
}
