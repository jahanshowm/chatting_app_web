/// PAY — 결제내역 목록·기간/필터
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/navigation/admin_screen_specs.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/utils/admin_list_query.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({
    super.key,
    required this.routePath,
    this.userId,
    this.fromPath,
  });

  final String routePath;
  final String? userId;
  /// CMS-01-03 — 탈퇴회원 등에서 진입 시 복귀 경로
  final String? fromPath;

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  late String _period;
  late DateTime _start;
  late DateTime _end;
  final _keyword = TextEditingController();
  late String _filter;
  late int _page;
  PaymentListResult? _data;
  final Set<String> _selected = {};
  bool _loading = true;

  static const _basePath = '/payments';

  AdminListQuery get _query => AdminListQuery(
        start: _start,
        end: _end,
        period: _period,
        filter: _filter,
        keyword: _keyword.text,
        page: _page,
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
      AdminListQuery.fromPath(widget.routePath, defaultPeriod: 'daily'),
      syncPath: false,
    );
    _load();
  }

  @override
  void didUpdateWidget(PaymentListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.routePath != widget.routePath) {
      final incoming =
          AdminListQuery.fromPath(widget.routePath, defaultPeriod: 'daily');
      if (!incoming.sameAs(_query) || oldWidget.userId != widget.userId) {
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
    _period = q.period ?? 'daily';
    _filter = q.filter;
    _page = q.page;
    if (_keyword.text != q.keyword) _keyword.text = q.keyword;
    if (syncPath) syncAdminListPath(ref, _basePath, _query);
  }

  void _persistAndLoad({bool resetPage = false}) {
    if (resetPage) _page = 1;
    syncAdminListPath(ref, _basePath, _query);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(adminApiProvider).payments(
            page: _page,
            filter: _filter == 'all' ? null : _filter,
            keyword: _keyword.text.trim(),
            startDate: DateRangeBar.formatApi(_start),
            endDate: DateRangeBar.formatApi(_end),
            period: _period,
            userId: widget.userId,
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

  void _resetSearch() {
    final d = AdminListQuery.today();
    setState(() {
      _period = 'daily';
      _start = d;
      _end = d;
      _filter = 'all';
      _page = 1;
      _keyword.clear();
    });
    _persistAndLoad();
  }

  void _clearUserFilter() {
    final back = widget.fromPath;
    if (back != null && back.isNotEmpty) {
      adminNavigateBack(ref, back);
      return;
    }
    final q = AdminListQuery(
      start: _start,
      end: _end,
      period: _period,
      filter: _filter,
      keyword: _keyword.text,
      page: 1,
    );
    adminNavigateReplace(ref, q.toPath(_basePath));
  }

  void _openMemberDetail(Map<String, dynamic> row) {
    final userId = row['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;
    // 결제 목록 필터를 유지한 채 복귀 (fromPath는 배너「필터 해제」용)
    adminNavigate(
      ref,
      '/members/$userId?from=${Uri.encodeComponent(_listPathWithQuery)}',
    );
  }

  int _selectedSum(List<Map<String, dynamic>> items) {
    var sum = 0;
    for (final row in items) {
      final id = row['id']?.toString();
      if (id == null || !_selected.contains(id)) continue;
      final amount = row['amount'];
      if (amount is int) {
        sum += amount;
      } else if (amount is num) {
        sum += amount.toInt();
      }
    }
    return sum;
  }

  int? _displaySum(List<Map<String, dynamic>> items) {
    if (_selected.isEmpty) return null;
    return _selectedSum(items);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final items = _data?.page.items ?? [];
    final totalCount = _data?.page.total ?? items.length;
    final totalPages = _data?.page.totalPages ?? 1;
    final selectedSum = _displaySum(items);

    return AdminContentArea(
      screenId: paymentSpec.id,
      subtitle: paymentSpec.subtitle,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.userId != null) ...[
            UserFilterBanner(
              userId: widget.userId!,
              label: '회원 결제내역',
              onClear: _clearUserFilter,
            ),
            const SizedBox(height: 16),
          ],
          DateRangeBar(
            start: _start,
            end: _end,
            period: _period,
            onPeriodChanged: (p) {
              final today = DateTime.now();
              setState(() {
                _period = p;
                if (p == 'weekly') {
                  _start = DateTime(today.year, today.month, today.day)
                      .subtract(const Duration(days: 6));
                  _end = today;
                } else if (p == 'monthly') {
                  _start = DateTime(today.year, today.month, 1);
                  _end = today;
                } else {
                  _start = DateTime(today.year, today.month, today.day);
                  _end = today;
                }
              });
              _persistAndLoad(resetPage: true);
            },
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
            filters: paymentSpec.filters,
            keywordController: _keyword,
            useSearchIcon: true,
            onFilterChanged: (v) => setState(() => _filter = v),
            onSearch: () => _persistAndLoad(resetPage: true),
            onReset: _resetSearch,
          ),
        ],
      ),
      summary: selectedSum == null
          ? null
          : Row(
              children: [
                const Spacer(),
                Text(
                  '선택합계 ${fmt.format(selectedSum)}원',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                              const DataColumn2(label: Text('휴대폰번호')),
                              const DataColumn2(label: Text('상품명')),
                              const DataColumn2(label: Text('결제일')),
                            ],
                            rows: items.map((row) {
                              final id = row['id'] as String;
                              final productLabel = formatProductWithAmount(
                                row['product_name']?.toString(),
                                row['amount'],
                                fmt,
                              );
                              return DataRow2(
                                onTap: () => _openMemberDetail(row),
                                cells: [
                                  DataCell(
                                    Checkbox(
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
                                    ),
                                  ),
                                  DataCell(GenderCellText('${row['gender'] ?? '-'}')),
                                  DataCell(Text('${row['name'] ?? '-'}')),
                                  DataCell(Text('${row['phone_number'] ?? '-'}')),
                                  DataCell(Text(productLabel)),
                                  DataCell(Text('${row['paid_at'] ?? '-'}')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        ListPageFooter(
                          page: _page,
                          totalPages: totalPages,
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
