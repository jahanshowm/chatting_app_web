import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/shared/utils/admin_date_format.dart';
import 'package:randomchat_admin/shared/utils/resolve_admin_media_url.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/navigation/admin_screen_specs.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_detail_back_bar.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';
import 'package:randomchat_admin/shared/widgets/notice_rich_editor.dart';
import 'package:randomchat_admin/shared/widgets/region_multi_select_field.dart';
import 'package:flutter_quill/flutter_quill.dart';

Widget _opsSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 8),
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  );
}

class PopupListScreen extends ConsumerStatefulWidget {
  const PopupListScreen({super.key});

  @override
  ConsumerState<PopupListScreen> createState() => _PopupListScreenState();
}

class _PopupListScreenState extends ConsumerState<PopupListScreen> {
  PaginatedResult<Map<String, dynamic>>? _data;
  final Set<String> _selected = {};
  bool _loading = true;
  int _page = 1;
  String _filter = 'all';
  final _keyword = TextEditingController();

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
      final data = await ref.read(adminApiProvider).popups(
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

  void _resetSearch() {
    setState(() {
      _filter = 'all';
      _page = 1;
      _keyword.clear();
    });
    _load();
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showConfirmDialog(
      context,
      title: '삭제 확인',
      message: '선택한 ${_selected.length}개의 항목을 삭제하시겠습니까?',
    );
    if (ok != true) return;
    await ref.read(adminApiProvider).deletePopups(_selected.toList());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _data?.items ?? [];
    final totalCount = _data?.total ?? items.length;
    final totalPages = _data?.totalPages ?? 1;

    return AdminContentArea(
      screenId: popupListSpec.id,
      subtitle: popupListSpec.subtitle,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () => adminNavigateReplace(ref, '/operations/popups/new'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.periodSelected,
                  foregroundColor: Colors.white,
                ),
                child: const Text('등록'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchFilterBar(
            filter: _filter,
            filters: popupListSpec.filters,
            keywordController: _keyword,
            hint: popupListSpec.searchHint,
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
      summary: Row(
        children: [
          const Spacer(),
          SelectDeleteButton(selectedCount: _selected.length, onDelete: _deleteSelected),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : AdminListPanel(
              child: items.isEmpty
                  ? const SizedBox(
                      height: 240,
                      child: Center(
                        child: AdminEmptyList(message: '등록된 팝업이 없습니다.'),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: DataTable2(
                            columnSpacing: 12,
                            minWidth: 1100,
                            headingRowColor: WidgetStateProperty.all(AppColors.inputBg),
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
                              const DataColumn2(label: Text('NO')),
                              const DataColumn2(label: Text('이미지')),
                              const DataColumn2(label: Text('제목')),
                              const DataColumn2(label: Text('조회수')),
                              const DataColumn2(label: Text('등록일')),
                              const DataColumn2(label: Text('사용')),
                              const DataColumn2(label: Text('관리')),
                            ],
                            rows: items.map((row) {
                              final id = row['id'] as String;
                              final imageUrl = resolveAdminMediaUrl(row['image_url'] as String?);
                              return DataRow(
                                selected: _selected.contains(id),
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
                                  DataCell(Text('${row['no'] ?? '-'}')),
                                  DataCell(
                                    imageUrl.isNotEmpty
                                        ? AdminAspectFitImage.network(
                                            url: imageUrl,
                                            maxWidth: 120,
                                            maxHeight: 48,
                                            borderRadius: 4,
                                            alignment: Alignment.center,
                                          )
                                        : const Text('-'),
                                  ),
                                  DataCell(Text('${row['title'] ?? '-'}')),
                                  DataCell(Text('${row['view_count'] ?? 0}')),
                                  DataCell(Text('${row['registered_at'] ?? '-'}')),
                                  DataCell(
                                    Switch(
                                      value: row['is_active'] == true,
                                      onChanged: (v) async {
                                        await ref.read(adminApiProvider).togglePopup(id, v);
                                        _load();
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () =>
                                          adminNavigateReplace(ref, '/operations/popups/$id/edit'),
                                      child: const Text('수정'),
                                    ),
                                  ),
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

class PopupFormScreen extends ConsumerStatefulWidget {
  const PopupFormScreen({super.key, this.popupId});

  final String? popupId;

  @override
  ConsumerState<PopupFormScreen> createState() => _PopupFormScreenState();
}

class _PopupFormScreenState extends ConsumerState<PopupFormScreen> {
  final _title = TextEditingController();
  final _link = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 7));
  bool _active = true;
  PlatformFile? _image;
  String? _existingImageUrl;
  bool _loading = false;
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    if (widget.popupId != null) {
      _loadPopup();
    }
  }

  Future<void> _loadPopup() async {
    setState(() => _loadingData = true);
    try {
      final data = await ref.read(adminApiProvider).popupDetail(widget.popupId!);
      _title.text = '${data['title']}';
      _link.text = '${data['link_url'] ?? ''}';
      _start = DateTime.parse('${data['start_at']}');
      _end = DateTime.parse('${data['end_at']}');
      _active = data['is_active'] == true;
      _existingImageUrl = data['image_url'] as String?;
      if (mounted) setState(() => _loadingData = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요')));
      return;
    }
    if (widget.popupId == null && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지를 선택해주세요.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final form = FormData.fromMap({
        'title': _title.text.trim(),
        'link_url': _link.text.trim(),
        'start_at': _start.toIso8601String(),
        'end_at': _end.toIso8601String(),
        'is_active': _active,
        if (_image != null)
          'image': MultipartFile.fromBytes(_image!.bytes!, filename: _image!.name),
      });
      if (widget.popupId == null) {
        await ref.read(adminApiProvider).createPopup(form);
      } else {
        await ref.read(adminApiProvider).updatePopup(widget.popupId!, form);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.popupId == null ? '정상적으로 등록되었습니다.' : '정상적으로 수정되었습니다.',
          ),
        ),
      );
      adminNavigateReplace(ref, '/operations/popups');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    final hasContent = _title.text.trim().isNotEmpty ||
        _link.text.trim().isNotEmpty ||
        _image != null;
    if (hasContent) {
      final ok = await showConfirmDialog(
        context,
        title: '나가기',
        message: '작성 중인 내용이 저장되지 않습니다. 나가시겠습니까?',
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    adminNavigateReplace(ref, '/operations/popups');
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());
    final isEdit = widget.popupId != null;
    return AdminContentArea(
      screenId: popupFormSpec.id,
      subtitle: isEdit ? '팝업 수정' : '팝업 등록',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminDetailBackBar(backPath: '/operations/popups'),
            _opsSectionTitle('노출기간'),
            Row(
              children: [
                OutlinedButton(onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _start,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _start = d);
                }, child: Text('시작 ${DateRangeBar.formatDisplay(_start)}')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _end,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _end = d);
                }, child: Text('종료 ${DateRangeBar.formatDisplay(_end)}')),
              ],
            ),
            _opsSectionTitle('제목'),
            TextField(
              controller: _title,
              decoration: const InputDecoration(hintText: '관리용 팝업 제목 (필수)'),
            ),
            _opsSectionTitle('이미지'),
            OutlinedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
                if (result != null && result.files.isNotEmpty) {
                  setState(() => _image = result.files.first);
                }
              },
              child: Text(_image == null ? '이미지 업로드' : _image!.name),
            ),
            if (_image?.bytes != null) ...[
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 600.0;
                  return AdminAspectFitImage.memory(
                    bytes: _image!.bytes!,
                    maxWidth: maxW,
                    maxHeight: 200,
                    borderRadius: 8,
                    alignment: Alignment.centerLeft,
                  );
                },
              ),
            ],
            if (_existingImageUrl != null && _image == null) ...[
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 600.0;
                  return AdminAspectFitImage.network(
                    url: resolveAdminMediaUrl(_existingImageUrl),
                    maxWidth: maxW,
                    maxHeight: 200,
                    borderRadius: 8,
                    alignment: Alignment.centerLeft,
                  );
                },
              ),
            ],
            _opsSectionTitle('연결 URL'),
            TextField(
              controller: _link,
              decoration: const InputDecoration(hintText: '팝업 클릭 시 이동할 페이지 주소'),
            ),
            _opsSectionTitle('사용 여부'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('팝업 노출'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _loading ? null : _cancel,
                  child: const Text('취소'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? '저장 중...' : (isEdit ? '수정' : '등록')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FcmListScreen extends ConsumerStatefulWidget {
  const FcmListScreen({super.key});

  @override
  ConsumerState<FcmListScreen> createState() => _FcmListScreenState();
}

class _FcmListScreenState extends ConsumerState<FcmListScreen> {
  int _page = 1;
  dynamic _data;
  bool _loading = true;
  late DateTime _start = DateTime.now().subtract(const Duration(days: 30));
  late DateTime _end = DateTime.now();
  final _keyword = TextEditingController();
  final Set<String> _selected = {};

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
      final data = await ref.read(adminApiProvider).fcmCampaigns(
            page: _page,
            startDate: DateRangeBar.formatApi(_start),
            endDate: DateRangeBar.formatApi(_end),
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
    await ref.read(adminApiProvider).deleteFcmCampaigns(_selected.toList());
    _load();
  }

  void _resetSearch() {
    final today = DateTime.now();
    setState(() {
      _start = today.subtract(const Duration(days: 30));
      _end = today;
      _page = 1;
      _keyword.clear();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = (_data?.items as List<Map<String, dynamic>>?) ?? [];
    final totalCount = _data?.total as int? ?? items.length;
    final totalPages = _data?.totalPages as int? ?? 1;

    return AdminContentArea(
      screenId: fcmListSpec.id,
      subtitle: fcmListSpec.subtitle,
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
                _page = 1;
              });
              _load();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keyword,
                  decoration: const InputDecoration(hintText: '제목 검색'),
                  onSubmitted: (_) {
                    setState(() => _page = 1);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() => _page = 1);
                  _load();
                },
                icon: const Icon(Icons.search),
              ),
              OutlinedButton(onPressed: _resetSearch, child: const Text('초기화')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => adminNavigateReplace(ref, '/operations/fcm/new'),
                child: const Text('FCM 발송'),
              ),
            ],
          ),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? AdminEmptyList(
                  message: _keyword.text.trim().isNotEmpty
                      ? '검색 결과가 없습니다.'
                      : '발송 이력이 없습니다.',
                )
              : Column(
                  children: [
                    Expanded(
                      child: DataTable2(
                        columnSpacing: 12,
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
                          const DataColumn2(label: Text('발송방법')),
                          const DataColumn2(label: Text('발송대상')),
                          const DataColumn2(label: Text('제목')),
                          const DataColumn2(label: Text('발송상태')),
                          const DataColumn2(label: Text('발송일')),
                        ],
                        rows: items.map((row) {
                          final id = row['id'] as String;
                          final sentAt = row['sent_at'];
                          String sentLabel = '-';
                          if (sentAt != null) {
                            try {
                              sentLabel = formatYmdHmDots(
                                DateTime.parse('$sentAt').toLocal(),
                              );
                            } catch (_) {
                              sentLabel = '$sentAt';
                            }
                          }
                          return DataRow2(
                            onTap: () => adminNavigateReplace(ref, '/operations/fcm/$id'),
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
                              DataCell(Text('${row['send_method'] ?? '-'}')),
                              DataCell(Text('${row['target_type'] ?? '-'}')),
                              DataCell(Text('${row['title'] ?? '-'}')),
                              DataCell(Text('${row['status'] ?? '-'}')),
                              DataCell(Text(sentLabel)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectDeleteButton(
                        selectedCount: _selected.length,
                        onDelete: _deleteSelected,
                      ),
                    ),
                    const SizedBox(height: 8),
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
    );
  }
}

class FcmDetailScreen extends ConsumerStatefulWidget {
  const FcmDetailScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<FcmDetailScreen> createState() => _FcmDetailScreenState();
}

class _FcmDetailScreenState extends ConsumerState<FcmDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(adminApiProvider).fcmDetail(widget.campaignId);
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

  String _formatDt(dynamic raw) {
    if (raw == null) return '-';
    try {
      return formatYmdHmDots(DateTime.parse('$raw').toLocal());
    } catch (_) {
      return '$raw';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final d = _data ?? {};

    return AdminContentArea(
      screenId: fcmListSpec.id,
      subtitle: 'FCM 발송 상세',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminDetailBackBar(backPath: '/operations/fcm'),
            sectionTitle('발송 상세정보'),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _DetailTile('발송방법', d['send_method']),
                _DetailTile('발송대상', d['target_type']),
                _DetailTile('발송상태', d['status']),
                _DetailTile('발송일', _formatDt(d['sent_at'])),
                _DetailTile('예약일', _formatDt(d['scheduled_at'])),
                _DetailTile('발송수', d['sent_count']),
              ],
            ),
            const SizedBox(height: 24),
            Text('제목', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text('${d['title'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text('내용', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text('${d['body'] ?? '-'}'),
            if (d['link_url'] != null) ...[
              const SizedBox(height: 16),
              Text('링크', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text('${d['link_url']}'),
            ],
            if (d['target_type'] == '타겟발송') ...[
              const SizedBox(height: 16),
              Text('타겟 조건', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '성별: ${d['target_genders'] ?? '-'} / '
                '연령: ${d['target_age_min'] ?? '-'}~${d['target_age_max'] ?? '-'} / '
                '지역: ${d['target_provinces'] ?? '-'}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile(this.label, this.value);

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('${value ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class FcmSendTypeScreen extends ConsumerStatefulWidget {
  const FcmSendTypeScreen({super.key});

  @override
  ConsumerState<FcmSendTypeScreen> createState() => _FcmSendTypeScreenState();
}

class _FcmSendTypeScreenState extends ConsumerState<FcmSendTypeScreen> {
  String _sendMethod = 'immediate';
  DateTime? _scheduledAt;

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _go(String targetPath) {
    final params = <String, String>{
      'send_method': _sendMethod,
      if (_sendMethod == 'scheduled' && _scheduledAt != null)
        'scheduled_at': _scheduledAt!.toIso8601String(),
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    adminNavigateReplace(ref, '$targetPath?$query');
  }

  @override
  Widget build(BuildContext context) {
    return AdminContentArea(
      screenId: fcmSendTypeSpec.id,
      subtitle: fcmSendTypeSpec.subtitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminDetailBackBar(backPath: '/operations/fcm'),
            _opsSectionTitle('발송 방식'),
            DropdownButtonFormField<String>(
              initialValue: _sendMethod,
              decoration: const InputDecoration(labelText: '즉시발송 / 예약발송'),
              items: const [
                DropdownMenuItem(value: 'immediate', child: Text('즉시발송')),
                DropdownMenuItem(value: 'scheduled', child: Text('예약발송')),
              ],
              onChanged: (v) => setState(() => _sendMethod = v ?? 'immediate'),
            ),
            if (_sendMethod == 'scheduled') ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _pickSchedule,
                child: Text(
                  _scheduledAt == null
                      ? '예약 일시 선택'
                      : '예약: ${formatYmdHmDots(_scheduledAt!)}',
                ),
              ),
            ],
            const SizedBox(height: 24),
            _opsSectionTitle('발송 대상'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (_sendMethod == 'scheduled' && _scheduledAt == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('예약 일시를 선택해주세요.')),
                        );
                        return;
                      }
                      _go('/operations/fcm/new/all');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                    child: const Text('전체발송'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_sendMethod == 'scheduled' && _scheduledAt == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('예약 일시를 선택해주세요.')),
                        );
                        return;
                      }
                      _go('/operations/fcm/new/target');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                    child: const Text('타겟발송'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FcmAllSendFormScreen extends ConsumerStatefulWidget {
  const FcmAllSendFormScreen({super.key, required this.sendMethod, this.scheduledAt});

  final String sendMethod;
  final DateTime? scheduledAt;

  @override
  ConsumerState<FcmAllSendFormScreen> createState() => _FcmAllSendFormScreenState();
}

class _FcmAllSendFormScreenState extends ConsumerState<FcmAllSendFormScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _link = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _link.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBody() {
    return {
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'link_url': _link.text.trim().isEmpty ? null : _link.text.trim(),
      'send_method': widget.sendMethod,
      'target_type': 'all',
      if (widget.sendMethod == 'scheduled' && widget.scheduledAt != null)
        'scheduled_at': widget.scheduledAt!.toIso8601String(),
    };
  }

  Future<void> _submit({bool test = false}) async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 제목과 내용을 입력해주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final body = _buildBody();
      if (test) {
        await ref.read(adminApiProvider).testFcm(body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('테스트 발송 완료')));
        }
      } else {
        await ref.read(adminApiProvider).createFcm(body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('발송이 완료되었습니다.')),
        );
        adminNavigateReplace(ref, '/operations/fcm');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminContentArea(
      screenId: fcmAllSendSpec.id,
      subtitle: fcmAllSendSpec.subtitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminDetailBackBar(backPath: '/operations/fcm/new'),
            _opsSectionTitle('내용 작성'),
            TextField(controller: _title, decoration: const InputDecoration(labelText: '알림 제목')),
            const SizedBox(height: 12),
            TextField(controller: _body, decoration: const InputDecoration(labelText: '알림 내용'), maxLines: 4),
            const SizedBox(height: 12),
            TextField(controller: _link, decoration: const InputDecoration(labelText: '링크(URL)')),
            const SizedBox(height: 32),
            Row(
              children: [
                OutlinedButton(onPressed: _loading ? null : () => _submit(test: true), child: const Text('테스트 발송')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _loading ? null : () => _submit(), child: const Text('발송하기')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FcmTargetSendFormScreen extends ConsumerStatefulWidget {
  const FcmTargetSendFormScreen({super.key, required this.sendMethod, this.scheduledAt});

  final String sendMethod;
  final DateTime? scheduledAt;

  @override
  ConsumerState<FcmTargetSendFormScreen> createState() => _FcmTargetSendFormScreenState();
}

class _FcmTargetSendFormScreenState extends ConsumerState<FcmTargetSendFormScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _link = TextEditingController();
  bool _targetMale = true;
  bool _targetFemale = true;
  int _ageMin = 20;
  int _ageMax = 70;
  Set<String> _selectedRegions = {};
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _link.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'link_url': _link.text.trim().isEmpty ? null : _link.text.trim(),
      'send_method': widget.sendMethod,
      'target_type': 'target',
    };
    if (widget.sendMethod == 'scheduled' && widget.scheduledAt != null) {
      body['scheduled_at'] = widget.scheduledAt!.toIso8601String();
    }
    final genders = <String>[];
    if (_targetMale) genders.add('male');
    if (_targetFemale) genders.add('female');
    body['target_genders'] = genders;
    body['target_age_min'] = _ageMin;
    body['target_age_max'] = _ageMax;
    if (_selectedRegions.isNotEmpty) {
      body['target_provinces'] = _selectedRegions.toList();
    }
    return body;
  }

  Future<void> _submit({bool test = false}) async {
    if (!_targetMale && !_targetFemale) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('성별을 1개 이상 선택해주세요.')));
      return;
    }
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 제목과 내용을 입력해주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final body = _buildBody();
      if (test) {
        await ref.read(adminApiProvider).testFcm(body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('테스트 발송 완료')));
        }
      } else {
        await ref.read(adminApiProvider).createFcm(body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('발송이 완료되었습니다.')),
        );
        adminNavigateReplace(ref, '/operations/fcm');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminContentArea(
      screenId: fcmTargetSendSpec.id,
      subtitle: fcmTargetSendSpec.subtitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminDetailBackBar(backPath: '/operations/fcm/new'),
            _opsSectionTitle('타겟 리스트'),
            Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('성별', style: TextStyle(fontWeight: FontWeight.w600)),
                FilterChip(
                  label: const Text('남성'),
                  selected: _targetMale,
                  onSelected: (v) => setState(() => _targetMale = v),
                ),
                FilterChip(
                  label: const Text('여성'),
                  selected: _targetFemale,
                  onSelected: (v) => setState(() => _targetFemale = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _ageMin,
                    decoration: const InputDecoration(labelText: '연령대(최소)'),
                    items: [for (var i = 20; i <= 70; i += 10) DropdownMenuItem(value: i, child: Text('${i}대'))],
                    onChanged: (v) => setState(() => _ageMin = v ?? 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _ageMax,
                    decoration: const InputDecoration(labelText: '연령대(최대)'),
                    items: [for (var i = 20; i <= 70; i += 10) DropdownMenuItem(value: i, child: Text('${i}대'))],
                    onChanged: (v) => setState(() => _ageMax = v ?? 70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RegionMultiSelectField(
              selected: _selectedRegions,
              onChanged: (v) => setState(() => _selectedRegions = v),
            ),
            _opsSectionTitle('내용 작성'),
            TextField(controller: _title, decoration: const InputDecoration(labelText: '알림 제목')),
            const SizedBox(height: 12),
            TextField(controller: _body, decoration: const InputDecoration(labelText: '알림 내용'), maxLines: 4),
            const SizedBox(height: 12),
            TextField(controller: _link, decoration: const InputDecoration(labelText: '링크(URL)')),
            const SizedBox(height: 32),
            Row(
              children: [
                OutlinedButton(onPressed: _loading ? null : () => _submit(test: true), child: const Text('테스트 발송')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _loading ? null : () => _submit(), child: const Text('발송하기')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NoticeListScreen extends ConsumerStatefulWidget {
  const NoticeListScreen({super.key});

  @override
  ConsumerState<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends ConsumerState<NoticeListScreen> {
  int _page = 1;
  dynamic _data;
  bool _loading = true;
  String _filter = 'all';
  final _keyword = TextEditingController();
  final Set<String> _selected = {};

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
      final data = await ref.read(adminApiProvider).notices(
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
    await ref.read(adminApiProvider).deleteNotices(_selected.toList());
    _load();
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
    final items = (_data?.items as List<Map<String, dynamic>>?) ?? [];
    final totalCount = _data?.total as int? ?? items.length;
    final totalPages = _data?.totalPages as int? ?? 1;

    return AdminContentArea(
      screenId: noticeSpec.id,
      subtitle: noticeSpec.subtitle,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () => adminNavigateReplace(ref, '/operations/notices/new'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.periodSelected,
                  foregroundColor: Colors.white,
                ),
                child: const Text('등록'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchFilterBar(
            filter: _filter,
            filters: noticeSpec.filters,
            keywordController: _keyword,
            hint: _filter == 'manage' ? '수정할 공지 제목 검색' : noticeSpec.searchHint,
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
      summary: Row(
        children: [
          const Spacer(),
          SelectDeleteButton(selectedCount: _selected.length, onDelete: _deleteSelected),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : AdminListPanel(
              child: items.isEmpty
                  ? SizedBox(
                      height: 240,
                      child: Center(
                        child: AdminEmptyList(
                          message: _keyword.text.trim().isNotEmpty
                              ? '검색 결과가 없습니다.'
                              : '등록된 공지사항이 없습니다.',
                        ),
                      ),
                    )
                  : Column(
                  children: [
                    Expanded(
                      child: DataTable2(
                        columnSpacing: 12,
                        minWidth: 800,
                        headingRowColor: WidgetStateProperty.all(AppColors.inputBg),
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
                          const DataColumn2(label: Text('NO')),
                          const DataColumn2(label: Text('제목')),
                          const DataColumn2(label: Text('조회수')),
                          const DataColumn2(label: Text('일자')),
                          const DataColumn2(label: Text('관리')),
                        ],
                        rows: items.map((row) {
                          final id = row['id'] as String;
                          return DataRow(
                            selected: _selected.contains(id),
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
                              DataCell(Text('${row['no'] ?? '-'}')),
                              DataCell(Text('${row['title'] ?? '-'}')),
                              DataCell(Text('${row['view_count'] ?? 0}')),
                              DataCell(Text('${row['date'] ?? '-'}')),
                              DataCell(
                                TextButton(
                                  onPressed: () => adminNavigateReplace(ref, '/operations/notices/$id/edit'),
                                  child: const Text('수정'),
                                ),
                              ),
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
                        _load();
                      },
                    ),
                  ],
                ),
            ),
    );
  }
}

class NoticeFormScreen extends ConsumerStatefulWidget {
  const NoticeFormScreen({super.key, this.noticeId});

  final String? noticeId;

  @override
  ConsumerState<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends ConsumerState<NoticeFormScreen> {
  final _title = TextEditingController();
  late final QuillController _quill = QuillController.basic();
  String? _initialHtml;
  bool _loading = false;
  bool _loadingData = false;
  bool _isPublished = true;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    if (widget.noticeId != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loadingData = true);
    try {
      final data = await ref.read(adminApiProvider).noticeDetail(widget.noticeId!);
      _title.text = '${data['title']}';
      _initialHtml = '${data['content']}';
      _isPublished = data['is_published'] as bool? ?? true;
      _isPinned = data['is_pinned'] as bool? ?? false;
      if (mounted) setState(() => _loadingData = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _quill.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final hasContent =
        _title.text.trim().isNotEmpty || !NoticeRichEditor.isEmpty(_quill);
    if (hasContent) {
      final ok = await showConfirmDialog(
        context,
        title: '나가기',
        message: '작성 중인 내용이 저장되지 않습니다. 나가시겠습니까?',
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    adminNavigateReplace(ref, '/operations/notices');
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요')));
      return;
    }
    if (NoticeRichEditor.isEmpty(_quill)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요')));
      return;
    }
    setState(() => _loading = true);
    try {
      final body = {
        'title': _title.text.trim(),
        'content': NoticeRichEditor.documentToHtml(_quill),
        'is_published': _isPublished,
        'is_pinned': _isPinned,
      };
      if (widget.noticeId == null) {
        await ref.read(adminApiProvider).createNotice(body);
      } else {
        await ref.read(adminApiProvider).updateNotice(widget.noticeId!, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.noticeId == null ? '정상적으로 등록되었습니다.' : '정상적으로 수정되었습니다.')),
      );
      adminNavigateReplace(ref, '/operations/notices');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());

    return AdminContentArea(
      screenId: noticeFormSpec.id,
      subtitle: widget.noticeId == null ? '공지 등록' : '공지 수정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminDetailBackBar(backPath: '/operations/notices'),
          TextField(controller: _title, decoration: const InputDecoration(labelText: '제목')),
          const SizedBox(height: 12),
          Row(
            children: [
              FilterChip(
                label: const Text('게시'),
                selected: _isPublished,
                onSelected: _loading ? null : (v) => setState(() => _isPublished = v),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('상단 고정'),
                selected: _isPinned,
                onSelected: _loading ? null : (v) => setState(() => _isPinned = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: NoticeRichEditor(
              key: ValueKey(_initialHtml ?? 'new'),
              controller: _quill,
              initialHtml: _initialHtml,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(onPressed: _loading ? null : _cancel, child: const Text('취소')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? '저장 중...' : (widget.noticeId == null ? '등록' : '수정')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
