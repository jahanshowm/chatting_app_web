import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_shell.dart';

class InquiryListScreen extends ConsumerStatefulWidget {
  const InquiryListScreen({super.key, this.withdrawn = false});

  final bool withdrawn;

  @override
  ConsumerState<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends ConsumerState<InquiryListScreen> {
  final _keyword = TextEditingController();
  int _page = 1;
  PaginatedResult<Map<String, dynamic>>? _data;
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
      final data = await ref.read(adminApiProvider).inquiries(
            page: _page,
            keyword: _keyword.text.trim(),
            withdrawn: widget.withdrawn,
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
    return AdminShell(
      title: widget.withdrawn ? '문의내역 (탈퇴회원)' : '문의내역',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.withdrawn)
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('활동 회원'),
                    onPressed: () => context.go('/inquiries'),
                  ),
                  ActionChip(
                    label: const Text('탈퇴 회원'),
                    onPressed: () => context.go('/inquiries/withdrawn'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keyword,
                    decoration: const InputDecoration(hintText: '이름 또는 제목 검색'),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _load, child: const Text('검색')),
              ],
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
                        DataColumn2(label: Text('제목')),
                        DataColumn2(label: Text('일자')),
                        DataColumn2(label: Text('상태')),
                        DataColumn2(label: Text('상세')),
                      ],
                      rows: (_data?.items ?? []).map((row) {
                        final id = row['id'] as String;
                        return DataRow(cells: [
                          DataCell(Text('${row['gender'] ?? '-'}')),
                          DataCell(Text('${row['name'] ?? '-'}')),
                          DataCell(Text('${row['title'] ?? '-'}')),
                          DataCell(Text('${row['date'] ?? '-'}')),
                          DataCell(Text('${row['status'] ?? '-'}')),
                          DataCell(
                            TextButton(
                              onPressed: () => context.go('/inquiries/$id'),
                              child: const Text('보기'),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
            ),
            PaginationBar(
              page: _page,
              totalPages: _data?.totalPages ?? 1,
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
