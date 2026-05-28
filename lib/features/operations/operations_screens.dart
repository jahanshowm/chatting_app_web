import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/navigation/admin_screen_specs.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_detail_back_bar.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';
import 'package:randomchat_admin/shared/widgets/notice_rich_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';

class PopupListScreen extends ConsumerStatefulWidget {
  const PopupListScreen({super.key});

  @override
  ConsumerState<PopupListScreen> createState() => _PopupListScreenState();
}

class _PopupListScreenState extends ConsumerState<PopupListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(adminApiProvider).popups();
      if (!mounted) return;
      setState(() {
        _items = items;
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
    return AdminContentArea(
      toolbar: Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton(
          onPressed: () => adminNavigateReplace(ref, '/operations/popups/new'),
          child: const Text('팝업 등록'),
        ),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const AdminEmptyList(message: '등록된 팝업이 없습니다.')
              : DataTable2(
                  columnSpacing: 12,
                  minWidth: 1100,
                  headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                  columns: const [
                    DataColumn2(label: Text('NO')),
                    DataColumn2(label: Text('이미지')),
                    DataColumn2(label: Text('제목')),
                    DataColumn2(label: Text('조회수')),
                    DataColumn2(label: Text('등록일')),
                    DataColumn2(label: Text('사용여부')),
                    DataColumn2(label: Text('관리')),
                  ],
                  rows: _items.map((row) {
                    final id = row['id'] as String;
                    final imageUrl = row['image_url'] as String?;
                    return DataRow(cells: [
                      DataCell(Text('${row['no'] ?? '-'}')),
                      DataCell(
                        imageUrl != null && imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
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
                          onPressed: () => adminNavigateReplace(ref, '/operations/popups/$id/edit'),
                          child: const Text('수정'),
                        ),
                      ),
                    ]);
                  }).toList(),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
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
      adminNavigateReplace(ref, '/operations/popups');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());
    final fmt = DateFormat('yyyy.MM.dd');
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminDetailBackBar(
            backPath: widget.popupId == null ? '/operations/popups' : '/operations/popups',
          ),
            TextField(controller: _title, decoration: const InputDecoration(hintText: '팝업 제목')),
            const SizedBox(height: 12),
            TextField(controller: _link, decoration: const InputDecoration(hintText: '링크 URL (선택)')),
            const SizedBox(height: 12),
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
                }, child: Text('시작 ${fmt.format(_start)}')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _end,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _end = d);
                }, child: Text('종료 ${fmt.format(_end)}')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('활성'),
                Switch(value: _active, onChanged: (v) => setState(() => _active = v)),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
                if (result != null && result.files.isNotEmpty) {
                  setState(() => _image = result.files.first);
                }
              },
              child: Text(_image == null ? '이미지 선택' : _image!.name),
            ),
            if (_existingImageUrl != null && _image == null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_existingImageUrl!, height: 120, fit: BoxFit.cover),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _loading ? null : () => adminNavigateReplace(ref, '/operations/popups'),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? '저장 중...' : '등록'),
                ),
              ],
            ),
          ],
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
  late DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _end = DateTime.now();
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
      final data = await ref.read(adminApiProvider).fcmCampaigns(
            page: _page,
            startDate: DateRangeBar.formatApi(_start),
            endDate: DateRangeBar.formatApi(_end),
            keyword: _keyword.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentFmt = DateFormat('yyyy.MM.dd HH:mm');
    final items = (_data?.items as List<Map<String, dynamic>>?) ?? [];

    return AdminContentArea(
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
              ? const AdminEmptyList()
              : Column(
                  children: [
                    Expanded(
                      child: DataTable2(
                        columnSpacing: 12,
                        minWidth: 960,
                        headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                        columns: const [
                          DataColumn2(label: Text('발송방법')),
                          DataColumn2(label: Text('발송대상')),
                          DataColumn2(label: Text('제목')),
                          DataColumn2(label: Text('발송상태')),
                          DataColumn2(label: Text('발송일')),
                        ],
                        rows: items.map((row) {
                          final sentAt = row['sent_at'];
                          String sentLabel = '-';
                          if (sentAt != null) {
                            try {
                              sentLabel = sentFmt.format(DateTime.parse('$sentAt').toLocal());
                            } catch (_) {
                              sentLabel = '$sentAt';
                            }
                          }
                          return DataRow(cells: [
                            DataCell(Text('${row['send_method'] ?? '-'}')),
                            DataCell(Text('${row['target_type'] ?? '-'}')),
                            DataCell(Text('${row['title'] ?? '-'}')),
                            DataCell(Text('${row['status'] ?? '-'}')),
                            DataCell(Text(sentLabel)),
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
    );
  }
}

class FcmFormScreen extends ConsumerStatefulWidget {
  const FcmFormScreen({super.key});

  @override
  ConsumerState<FcmFormScreen> createState() => _FcmFormScreenState();
}

class _FcmFormScreenState extends ConsumerState<FcmFormScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _link = TextEditingController();
  final _province = TextEditingController();
  String _sendMethod = 'immediate';
  String _targetType = 'all';
  bool _targetMale = true;
  bool _targetFemale = true;
  int _ageMin = 20;
  int _ageMax = 70;
  DateTime? _scheduledAt;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _link.dispose();
    _province.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'link_url': _link.text.trim().isEmpty ? null : _link.text.trim(),
      'send_method': _sendMethod,
      'target_type': _targetType,
    };
    if (_sendMethod == 'scheduled' && _scheduledAt != null) {
      body['scheduled_at'] = _scheduledAt!.toIso8601String();
    }
    if (_targetType == 'target') {
      final genders = <String>[];
      if (_targetMale) genders.add('male');
      if (_targetFemale) genders.add('female');
      body['target_genders'] = genders;
      body['target_age_min'] = _ageMin;
      body['target_age_max'] = _ageMax;
      if (_province.text.trim().isNotEmpty) {
        body['target_provinces'] = [_province.text.trim()];
      }
    }
    return body;
  }

  Future<void> _submit({bool test = false}) async {
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
        adminNavigateReplace(ref, '/operations/fcm');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy.MM.dd HH:mm');
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminDetailBackBar(backPath: '/operations/fcm'),
          TextField(controller: _title, decoration: const InputDecoration(labelText: '알림 제목')),
          const SizedBox(height: 12),
          TextField(controller: _body, decoration: const InputDecoration(labelText: '알림 내용'), maxLines: 4),
          const SizedBox(height: 12),
          TextField(controller: _link, decoration: const InputDecoration(labelText: '링크(URL)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _sendMethod,
            decoration: const InputDecoration(labelText: '발송 방식'),
            items: const [
              DropdownMenuItem(value: 'immediate', child: Text('즉시발송')),
              DropdownMenuItem(value: 'scheduled', child: Text('예약발송')),
            ],
            onChanged: (v) => setState(() => _sendMethod = v ?? 'immediate'),
          ),
          if (_sendMethod == 'scheduled') ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
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
              },
              child: Text(_scheduledAt == null ? '예약 일시 선택' : '예약: ${fmt.format(_scheduledAt!)}'),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _targetType,
            decoration: const InputDecoration(labelText: '발송 대상'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('전체발송')),
              DropdownMenuItem(value: 'target', child: Text('타겟발송')),
            ],
            onChanged: (v) => setState(() => _targetType = v ?? 'all'),
          ),
          if (_targetType == 'target') ...[
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            TextField(
              controller: _province,
              decoration: const InputDecoration(labelText: '지역(시/군/구)'),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              OutlinedButton(onPressed: _loading ? null : () => _submit(test: true), child: const Text('테스트 발송')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: _loading ? null : () => _submit(), child: const Text('발송하기')),
            ],
          ),
        ],
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
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_data?.items as List<Map<String, dynamic>>?) ?? [];

    return AdminContentArea(
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () => adminNavigateReplace(ref, '/operations/notices/new'),
                child: const Text('등록'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchFilterBar(
            filter: _filter,
            filters: noticeSpec.filters,
            keywordController: _keyword,
            hint: noticeSpec.searchHint,
            useSearchIcon: true,
            onFilterChanged: (v) => setState(() => _filter = v),
            onSearch: () {
              setState(() => _page = 1);
              _load();
            },
          ),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const AdminEmptyList()
              : Column(
                  children: [
                    Expanded(
                      child: DataTable2(
                        columnSpacing: 12,
                        minWidth: 800,
                        headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                        columns: const [
                          DataColumn2(label: Text('제목')),
                          DataColumn2(label: Text('조회수')),
                          DataColumn2(label: Text('일자')),
                          DataColumn2(label: Text('관리')),
                        ],
                        rows: items.map((row) {
                          final id = row['id'] as String;
                          return DataRow(cells: [
                            DataCell(Text('${row['title'] ?? '-'}')),
                            DataCell(Text('${row['view_count'] ?? 0}')),
                            DataCell(Text('${row['date'] ?? '-'}')),
                            DataCell(
                              TextButton(
                                onPressed: () => adminNavigateReplace(ref, '/operations/notices/$id/edit'),
                                child: const Text('수정'),
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
  bool _published = true;
  bool _pinned = false;
  bool _loading = false;
  bool _loadingData = false;

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
      _published = data['is_published'] == true;
      _pinned = data['is_pinned'] == true;
      if (mounted) setState(() => _loadingData = false);
    } catch (e) {
      if (mounted) setState(() => _loadingData = false);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
      return;
    }
    if (NoticeRichEditor.isEmpty(_quill)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final body = {
        'title': _title.text.trim(),
        'content': NoticeRichEditor.documentToHtml(_quill),
        'is_published': _published,
        'is_pinned': _pinned,
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

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminDetailBackBar(backPath: '/operations/notices'),
          TextField(controller: _title, decoration: const InputDecoration(labelText: '제목')),
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
              Checkbox(value: _published, onChanged: (v) => setState(() => _published = v ?? true)),
              const Text('게시'),
              const SizedBox(width: 24),
              Checkbox(value: _pinned, onChanged: (v) => setState(() => _pinned = v ?? false)),
              const Text('상단 고정'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(onPressed: _loading ? null : _cancel, child: const Text('취소')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? '저장 중...' : '등록'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
