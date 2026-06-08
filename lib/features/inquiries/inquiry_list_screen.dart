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

class InquiryListScreen extends ConsumerStatefulWidget {
  const InquiryListScreen({super.key, this.withdrawn = false, this.userId});

  final bool withdrawn;
  final String? userId;

  @override
  ConsumerState<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends ConsumerState<InquiryListScreen> {
  final _keyword = TextEditingController();
  Set<String> _statusFilter = {'all'};
  int _page = 1;
  PaginatedResult<Map<String, dynamic>>? _data;
  bool _loading = true;

  AdminScreenSpec get _spec => widget.withdrawn ? inquiryWithdrawnSpec : inquiryActiveSpec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(InquiryListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.withdrawn != widget.withdrawn) {
      _page = 1;
      _keyword.clear();
      _statusFilter = {'all'};
      _load();
    }
  }

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  List<String>? get _apiStatuses {
    if (_statusFilter.contains('all') || _statusFilter.isEmpty) return null;
    return _statusFilter.toList();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _openDetail(String id) {
    final from = widget.withdrawn ? '/inquiries/withdrawn' : '/inquiries/active';
    adminNavigateReplace(
      ref,
      '/inquiries/$id?from=${Uri.encodeComponent(from)}',
    );
  }

  void _resetSearch() {
    setState(() {
      _statusFilter = {'all'};
      _page = 1;
      _keyword.clear();
    });
    _load();
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
              onClear: () => adminNavigateReplace(
                ref,
                widget.withdrawn ? '/inquiries/withdrawn' : '/inquiries/active',
              ),
            ),
            const SizedBox(height: 16),
          ],
          InquiryStatusFilterBar(
            selected: _statusFilter,
            onChanged: (next) {
              setState(() {
                _statusFilter = next;
                _page = 1;
              });
              _load();
            },
          ),
          const SizedBox(height: 16),
          SearchFilterBar(
            filter: 'all',
            filters: const [],
            keywordController: _keyword,
            hint: spec.searchHint,
            useSearchIcon: false,
            onSearch: () {
              setState(() => _page = 1);
              _load();
            },
            onReset: _resetSearch,
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
                        headingRowColor: WidgetStateProperty.all(AppColors.inputBg),
                        columns: const [
                          DataColumn2(label: Text('성별')),
                          DataColumn2(label: Text('이름')),
                          DataColumn2(label: Text('문의제목')),
                          DataColumn2(label: Text('일자')),
                          DataColumn2(label: Text('처리상태')),
                        ],
                        rows: items.map((row) {
                          final id = row['id'] as String;
                          return DataRow2(
                            onTap: () => _openDetail(id),
                            cells: [
                              DataCell(GenderCellText('${row['gender'] ?? '-'}')),
                              DataCell(Text('${row['name'] ?? '-'}')),
                              DataCell(Text('${row['title'] ?? '-'}')),
                              DataCell(Text('${row['date'] ?? '-'}')),
                              DataCell(_StatusBadge(label: '${row['status'] ?? '-'}')),
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
                        _load();
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
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
