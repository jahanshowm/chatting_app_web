import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_shell.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({super.key});

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  late DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _end = DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return AdminShell(
      title: '결제내역',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                ('product_name', '상품'),
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
            Text(
              '선택 기간 결제 합계: ${fmt.format(_data?.selectedSum ?? 0)}원',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : DataTable2(
                      columnSpacing: 12,
                      minWidth: 900,
                      headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                      columns: const [
                        DataColumn2(label: Text('성별')),
                        DataColumn2(label: Text('이름')),
                        DataColumn2(label: Text('연락처')),
                        DataColumn2(label: Text('상품')),
                        DataColumn2(label: Text('결제일')),
                      ],
                      rows: (_data?.page.items ?? []).map((row) {
                        return DataRow(cells: [
                          DataCell(Text('${row['gender'] ?? '-'}')),
                          DataCell(Text('${row['name'] ?? '-'}')),
                          DataCell(Text('${row['phone_number'] ?? '-'}')),
                          DataCell(Text('${row['product_name'] ?? '-'}')),
                          DataCell(Text('${row['paid_at'] ?? '-'}')),
                        ]);
                      }).toList(),
                    ),
            ),
            PaginationBar(
              page: _page,
              totalPages: _data?.page.totalPages ?? 1,
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
