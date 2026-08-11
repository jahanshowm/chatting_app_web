/// INQ — 활동/탈퇴 회원 문의 목록
import 'dart:async';

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

class InquiryListScreen extends ConsumerStatefulWidget {
  const InquiryListScreen({
    super.key,
    required this.routePath,
    this.withdrawn = false,
    this.userId,
    this.fromPath,
  });

  final String routePath;
  final bool withdrawn;
  /// CMS-01-03 — 탈퇴회원에서 진입 시 복귀 경로
  final String? fromPath;
  final String? userId;

  @override
  ConsumerState<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends ConsumerState<InquiryListScreen> {
  final _keyword = TextEditingController();
  late Set<String> _statusFilter;
  late int _page;
  PaginatedResult<Map<String, dynamic>>? _data;
  final Set<String> _selected = {};
  bool _loading = true;
  Timer? _pollTimer;

  AdminScreenSpec get _spec =>
      widget.withdrawn ? inquiryWithdrawnSpec : inquiryActiveSpec;

  String get _basePath =>
      widget.withdrawn ? '/inquiries/withdrawn' : '/inquiries/active';

  AdminListQuery get _query => AdminListQuery(
        start: AdminListQuery.today(),
        end: AdminListQuery.today(),
        filter: 'all',
        keyword: _keyword.text,
        page: _page,
        statuses: _statusFilter,
        persistDates: false,
        extra: {
          if (widget.userId != null && widget.userId!.isNotEmpty)
            'user_id': widget.userId!,
          if (widget.fromPath != null && widget.fromPath!.isNotEmpty)
            'from': widget.fromPath!,
        },
      );

  String get _listPathWithQuery => _query.toPath(_basePath);

  @override
  void initState() {
    super.initState();
    _applyQuery(
      AdminListQuery.fromPath(widget.routePath, persistDates: false),
      syncPath: false,
    );
    _load();
    _startPollIfNeeded();
  }

  void _startPollIfNeeded() {
    _pollTimer?.cancel();
    if (!widget.withdrawn) {
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || _loading) return;
        _load(silent: true);
      });
    }
  }

  @override
  void didUpdateWidget(InquiryListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.withdrawn != widget.withdrawn) {
      _applyQuery(
        AdminListQuery.fromPath(widget.routePath, persistDates: false),
        syncPath: false,
      );
      _startPollIfNeeded();
      _load();
      return;
    }
    if (oldWidget.routePath != widget.routePath ||
        oldWidget.userId != widget.userId) {
      final incoming =
          AdminListQuery.fromPath(widget.routePath, persistDates: false);
      if (!incoming.sameAs(_query) || oldWidget.userId != widget.userId) {
        _applyQuery(incoming, syncPath: false);
        _load();
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _keyword.dispose();
    super.dispose();
  }

  void _applyQuery(AdminListQuery q, {required bool syncPath}) {
    _page = q.page;
    _statusFilter = (q.statuses == null || q.statuses!.isEmpty)
        ? {'all'}
        : {...q.statuses!};
    if (_keyword.text != q.keyword) _keyword.text = q.keyword;
    if (syncPath) syncAdminListPath(ref, _basePath, _query);
  }

  void _persistAndLoad({bool resetPage = false}) {
    if (resetPage) _page = 1;
    syncAdminListPath(ref, _basePath, _query);
    _load();
  }

  List<String>? get _apiStatuses {
    if (_statusFilter.contains('all') || _statusFilter.isEmpty) return null;
    return _statusFilter.toList();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await ref.read(adminApiProvider).inquiries(
            page: _page,
            keyword: _keyword.text.trim(),
            withdrawn: widget.withdrawn,
            statuses: _apiStatuses,
            userId: widget.userId,
          );
      if (!mounted) return;
      setState(() {
        _data = data;
        if (!silent) _selected.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!silent) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openDetail(String id) {
    adminNavigate(
      ref,
      '/inquiries/$id?from=${Uri.encodeComponent(_listPathWithQuery)}',
    );
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showConfirmDialog(
      context,
      title: '삭제 확인',
      message: '선택한 ${_selected.length}개의 항목을 삭제하시겠습니까?',
    );
    if (ok != true) return;
    await ref.read(adminApiProvider).deleteInquiries(_selected.toList());
    _load();
  }

  void _resetSearch() {
    setState(() {
      _statusFilter = {'all'};
      _page = 1;
      _keyword.clear();
    });
    _persistAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final items = _data?.items ?? [];
    final totalCount = _data?.total ?? items.length;

    return AdminContentArea(
      screenId: spec.id,
      subtitle: spec.subtitle,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.userId != null) ...[
            UserFilterBanner(
              userId: widget.userId!,
              label: widget.withdrawn ? '탈퇴 회원 문의내역' : '회원 문의내역',
              onClear: () {
                if (widget.fromPath != null && widget.fromPath!.isNotEmpty) {
                  adminNavigateBack(ref, widget.fromPath!);
                } else {
                  adminNavigateReplace(
                    ref,
                    AdminListQuery(
                      start: AdminListQuery.today(),
                      end: AdminListQuery.today(),
                      keyword: _keyword.text,
                      page: 1,
                      statuses: _statusFilter,
                      persistDates: false,
                    ).toPath(_basePath),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          InquiryStatusFilterBar(
            selected: _statusFilter,
            onChanged: (next) {
              setState(() => _statusFilter = next);
              _persistAndLoad(resetPage: true);
            },
          ),
          const SizedBox(height: 16),
          SearchFilterBar(
            filter: 'all',
            filters: const [],
            keywordController: _keyword,
            hint: spec.searchHint,
            useSearchIcon: false,
            onSearch: () => _persistAndLoad(resetPage: true),
            onReset: _resetSearch,
          ),
        ],
      ),
      summary: Row(
        children: [
          const Spacer(),
          SelectDeleteButton(
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
                            minWidth: 960,
                            headingRowColor:
                                WidgetStateProperty.all(AppColors.inputBg),
                            columns: [
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
                              const DataColumn2(label: Text('성별')),
                              const DataColumn2(label: Text('이름')),
                              const DataColumn2(label: Text('문의제목')),
                              const DataColumn2(label: Text('일자')),
                              const DataColumn2(label: Text('처리상태')),
                            ],
                            rows: items.map((row) {
                              final id = row['id'] as String;
                              return DataRow2(
                                onTap: () => _openDetail(id),
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
                                  DataCell(
                                    GenderCellText('${row['gender'] ?? '-'}'),
                                  ),
                                  DataCell(Text('${row['name'] ?? '-'}')),
                                  DataCell(Text('${row['title'] ?? '-'}')),
                                  DataCell(Text('${row['date'] ?? '-'}')),
                                  DataCell(
                                    _StatusBadge(
                                      label: '${row['status'] ?? '-'}',
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        ListPageFooter(
                          page: _page,
                          totalPages: _data?.totalPages ?? 1,
                          totalCount: totalCount,
                          unit: '건',
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.textSecondary;
    if (label.contains('대기')) color = const Color(0xFF999999);
    if (label.contains('진행')) color = const Color(0xFF4A90E2);
    if (label.contains('완료')) color = AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
