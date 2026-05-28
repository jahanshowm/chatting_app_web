import 'package:data_table_2/data_table_2.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_shell.dart';

class PopupListScreen extends ConsumerStatefulWidget {
  const PopupListScreen({super.key});

  @override
  ConsumerState<PopupListScreen> createState() => _PopupListScreenState();
}

class _PopupListScreenState extends ConsumerState<PopupListScreen> {
  List<Map<String, dynamic>> _items = [];
  final Set<String> _selected = {};
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
    final ok = await showConfirmDialog(context, title: '삭제 확인', message: '선택한 팝업을 삭제하시겠습니까?');
    if (ok != true) return;
    await ref.read(adminApiProvider).deletePopups(_selected.toList());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: '운영관리 · 팝업',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OpsTabs(current: 'popups'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(onPressed: () => context.go('/operations/popups/new'), child: const Text('팝업 등록')),
                const Spacer(),
                OutlinedButton(onPressed: _deleteSelected, child: const Text('선택 삭제')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : DataTable2(
                      columnSpacing: 12,
                      minWidth: 1000,
                      headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                      columns: const [
                        DataColumn2(label: Text('선택')),
                        DataColumn2(label: Text('No')),
                        DataColumn2(label: Text('제목')),
                        DataColumn2(label: Text('조회수')),
                        DataColumn2(label: Text('등록일')),
                        DataColumn2(label: Text('활성')),
                        DataColumn2(label: Text('수정')),
                      ],
                      rows: _items.map((row) {
                        final id = row['id'] as String;
                        return DataRow(cells: [
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
                              onPressed: () => context.go('/operations/popups/$id/edit'),
                              child: const Text('수정'),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
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
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
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
      context.go('/operations/popups');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy.MM.dd');
    return AdminShell(
      title: widget.popupId == null ? '팝업 등록' : '팝업 수정',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const Spacer(),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? '저장 중...' : '저장'),
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(adminApiProvider).fcmCampaigns(page: _page);
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
    return AdminShell(
      title: '운영관리 · FCM',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _OpsTabs(current: 'fcm'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () => context.go('/operations/fcm/new'),
                child: const Text('FCM 발송'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : DataTable2(
                      columns: const [
                        DataColumn2(label: Text('발송방식')),
                        DataColumn2(label: Text('대상')),
                        DataColumn2(label: Text('제목')),
                        DataColumn2(label: Text('상태')),
                      ],
                      rows: (_data?.items as List<Map<String, dynamic>>? ?? []).map((row) {
                        return DataRow(cells: [
                          DataCell(Text('${row['send_method'] ?? '-'}')),
                          DataCell(Text('${row['target_type'] ?? '-'}')),
                          DataCell(Text('${row['title'] ?? '-'}')),
                          DataCell(Text('${row['status'] ?? '-'}')),
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

class FcmFormScreen extends ConsumerStatefulWidget {
  const FcmFormScreen({super.key});

  @override
  ConsumerState<FcmFormScreen> createState() => _FcmFormScreenState();
}

class _FcmFormScreenState extends ConsumerState<FcmFormScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _link = TextEditingController();
  String _sendMethod = 'immediate';
  String _targetType = 'all';
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _submit({bool test = false}) async {
    setState(() => _loading = true);
    try {
      final body = {
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'link_url': _link.text.trim().isEmpty ? null : _link.text.trim(),
        'send_method': _sendMethod,
        'target_type': _targetType,
      };
      if (test) {
        await ref.read(adminApiProvider).testFcm(body);
      } else {
        await ref.read(adminApiProvider).createFcm(body);
      }
      if (!mounted) return;
      context.go('/operations/fcm');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'FCM 발송',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _title, decoration: const InputDecoration(hintText: '제목')),
            const SizedBox(height: 12),
            TextField(controller: _body, decoration: const InputDecoration(hintText: '내용'), maxLines: 4),
            const SizedBox(height: 12),
            TextField(controller: _link, decoration: const InputDecoration(hintText: '링크 (선택)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _sendMethod,
              items: const [
                DropdownMenuItem(value: 'immediate', child: Text('즉시발송')),
                DropdownMenuItem(value: 'scheduled', child: Text('예약발송')),
              ],
              onChanged: (v) => setState(() => _sendMethod = v ?? 'immediate'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _targetType,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('전체발송')),
                DropdownMenuItem(value: 'target', child: Text('타겟발송')),
              ],
              onChanged: (v) => setState(() => _targetType = v ?? 'all'),
            ),
            const Spacer(),
            Row(
              children: [
                OutlinedButton(onPressed: _loading ? null : () => _submit(test: true), child: const Text('테스트 발송')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _loading ? null : () => _submit(), child: const Text('발송')),
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
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(adminApiProvider).notices(page: _page);
      if (!mounted) return;
      setState(() {
        _data = data;
        _selected.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showConfirmDialog(context, title: '삭제 확인', message: '선택한 공지를 삭제하시겠습니까?');
    if (ok != true) return;
    await ref.read(adminApiProvider).deleteNotices(_selected.toList());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: '운영관리 · 공지사항',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _OpsTabs(current: 'notices'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(onPressed: () => context.go('/operations/notices/new'), child: const Text('공지 등록')),
                const Spacer(),
                OutlinedButton(onPressed: _deleteSelected, child: const Text('선택 삭제')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : DataTable2(
                      columns: const [
                        DataColumn2(label: Text('선택')),
                        DataColumn2(label: Text('제목')),
                        DataColumn2(label: Text('조회수')),
                        DataColumn2(label: Text('일자')),
                        DataColumn2(label: Text('수정')),
                      ],
                      rows: (_data?.items as List<Map<String, dynamic>>? ?? []).map((row) {
                        final id = row['id'] as String;
                        return DataRow(cells: [
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
                          DataCell(Text('${row['title'] ?? '-'}')),
                          DataCell(Text('${row['view_count'] ?? 0}')),
                          DataCell(Text('${row['date'] ?? '-'}')),
                          DataCell(TextButton(onPressed: () => context.go('/operations/notices/$id/edit'), child: const Text('수정'))),
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

class NoticeFormScreen extends ConsumerStatefulWidget {
  const NoticeFormScreen({super.key, this.noticeId});

  final String? noticeId;

  @override
  ConsumerState<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends ConsumerState<NoticeFormScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _published = true;
  bool _pinned = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.noticeId != null) _load();
  }

  Future<void> _load() async {
    final data = await ref.read(adminApiProvider).noticeDetail(widget.noticeId!);
    _title.text = '${data['title']}';
    _content.text = '${data['content']}';
    _published = data['is_published'] == true;
    _pinned = data['is_pinned'] == true;
    setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final body = {
        'title': _title.text.trim(),
        'content': _content.text.trim(),
        'is_published': _published,
        'is_pinned': _pinned,
      };
      if (widget.noticeId == null) {
        await ref.read(adminApiProvider).createNotice(body);
      } else {
        await ref.read(adminApiProvider).updateNotice(widget.noticeId!, body);
      }
      if (!mounted) return;
      context.go('/operations/notices');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: widget.noticeId == null ? '공지 등록' : '공지 수정',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _title, decoration: const InputDecoration(hintText: '제목')),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _content,
                decoration: const InputDecoration(hintText: '내용'),
                maxLines: null,
                expands: true,
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
            ElevatedButton(onPressed: _loading ? null : _submit, child: Text(_loading ? '저장 중...' : '저장')),
          ],
        ),
      ),
    );
  }
}

class _OpsTabs extends StatelessWidget {
  const _OpsTabs({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    Widget tab(String key, String label, String path) {
      final selected = current == key;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          selectedColor: AppColors.secondary,
          onSelected: (_) => context.go(path),
        ),
      );
    }

    return Wrap(
      children: [
        tab('popups', '팝업', '/operations/popups'),
        tab('fcm', 'FCM', '/operations/fcm'),
        tab('notices', '공지사항', '/operations/notices'),
      ],
    );
  }
}
