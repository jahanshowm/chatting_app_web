import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/navigation/admin_screen_specs.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({super.key, this.userId});

  final String? userId;

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  String _period = 'daily';
  late DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _end = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final _keyword = TextEditingController();
  String _filter = 'all';
  int _page = 1;
  PaymentListResult? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PaymentListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _page = 1;
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
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _resetSearch() {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    setState(() {
      _period = 'daily';
      _start = d;
      _end = d;
      _filter = 'all';
      _page = 1;
      _keyword.clear();
    });
    _load();
  }

  void _clearUserFilter() {
    adminNavigateReplace(ref, '/payments');
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final items = _data?.page.items ?? [];
    final totalCount = _data?.page.total ?? items.length;
    final totalPages = _data?.page.totalPages ?? 1;

    return AdminContentArea(
      screenId: paymentSpec.id,
      subtitle: paymentSpec.subtitle,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.userId != null) ...[
            UserFilterBanner(
              userId: widget.userId!,
              label: '탈퇴 회원 결제내역',
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
                _page = 1;
              });
              _load();
            },
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
            filters: paymentSpec.filters,
            keywordController: _keyword,
            useSearchIcon: true,
            onFilterChanged: (v) => setState(() => _filter = v),
            onSearch: () {
              setState(() => _page = 1);
              _load();
            },
            onReset: _resetSearch,
          ),
        ],
      ),
      summary: Text(
        '선택합계 ${fmt.format(_data?.selectedSum ?? 0)}원',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                        headingRowColor: WidgetStateProperty.all(AppColors.inputBg),
                        columns: const [
                          DataColumn2(label: Text('성별')),
                          DataColumn2(label: Text('이름')),
                          DataColumn2(label: Text('휴대폰번호')),
                          DataColumn2(label: Text('상품명')),
                          DataColumn2(label: Text('결제일')),
                        ],
                        rows: items.map((row) {
                          final productLabel = formatProductWithAmount(
                            row['product_name']?.toString(),
                            row['amount'],
                            fmt,
                          );
                          return DataRow(cells: [
                            DataCell(GenderCellText('${row['gender'] ?? '-'}')),
                            DataCell(Text('${row['name'] ?? '-'}')),
                            DataCell(Text('${row['phone_number'] ?? '-'}')),
                            DataCell(Text(productLabel)),
                            DataCell(Text('${row['paid_at'] ?? '-'}')),
                          ]);
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
                        _load();
                      },
                    ),
                  ],
                ),
            ),
    );
  }
}
