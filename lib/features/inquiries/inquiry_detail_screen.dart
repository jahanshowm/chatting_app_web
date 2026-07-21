import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/navigation/admin_screen_specs.dart';
import 'package:randomchat_admin/shared/utils/admin_date_format.dart';
import 'package:randomchat_admin/core/providers/auth_provider.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_detail_back_bar.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';
import 'package:randomchat_admin/shared/widgets/member_info_header.dart';
import 'package:randomchat_admin/shared/utils/resolve_admin_media_url.dart';

class InquiryDetailScreen extends ConsumerStatefulWidget {
  const InquiryDetailScreen({
    super.key,
    required this.inquiryId,
    this.listPath = '/inquiries/active',
  });

  final String inquiryId;
  final String listPath;

  @override
  ConsumerState<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends ConsumerState<InquiryDetailScreen> {
  InquiryThread? _thread;
  final _message = TextEditingController();
  PlatformFile? _pendingImage;
  bool _loading = true;
  bool _sending = false;
  bool _pickingImage = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // A2 — 상세에서도 새로고침 없이 유저 메시지 갱신
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _loading || _sending) return;
      _load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _message.dispose();
    super.dispose();
  }

  String _formatTime(dynamic raw) {
    final dt = tryParseApiDateTime(raw);
    if (dt == null) return raw == null ? '' : '$raw';
    return formatAmPmTime(dt).toUpperCase();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final thread = await ref.read(adminApiProvider).inquiryMessages(widget.inquiryId);
      if (!mounted) return;
      setState(() {
        _thread = thread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _pickImage() async {
    if (_pickingImage || _sending) return;
    _pickingImage = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.image,
      );
      if (!mounted) return;
      if (result != null && result.files.isNotEmpty) {
        setState(() => _pendingImage = result.files.first);
      }
    } finally {
      _pickingImage = false;
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(adminApiProvider).sendInquiryMessage(
            widget.inquiryId,
            content: text.isEmpty ? null : text,
            imageBytes: _pendingImage?.bytes,
            imageName: _pendingImage?.name,
          );
      _message.clear();
      setState(() => _pendingImage = null);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  List<String> get _photos {
    final raw = _thread?.member['photos'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  Widget _memberAvatar(String memberName) {
    final photos = _photos;
    if (photos.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.border,
        backgroundImage: NetworkImage(resolveAdminMediaUrl(photos.first)),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.border,
      child: Text(memberName.characters.first),
    );
  }

  Widget _adminAvatar() {
    final admin = ref.watch(authProvider).admin;
    final display = (admin?.name?.trim().isNotEmpty == true)
        ? admin!.name!.trim()
        : (admin?.username ?? '관리');
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary,
      child: Text(
        display.characters.first,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _messageBubble({
    required String? content,
    required String? imageUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (content != null && content.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.chatBubble,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              content,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          if (content != null && content.isNotEmpty) const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              resolveAdminMediaUrl(imageUrl),
              width: 200,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return AdminContentArea(
      screenId: inquiryDetailSpec.id,
      subtitle: inquiryDetailSpec.subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminDetailBackBar(backPath: widget.listPath),
          MemberInfoHeader(data: _thread?.member ?? {}, photos: _photos),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _thread?.messages.length ?? 0,
                itemBuilder: (context, index) {
                  final msg = _thread!.messages[index];
                  final isAdmin = msg['is_admin'] == true;
                  final memberName = '${_thread!.member['name'] ?? '?'}';
                  final imageUrl = msg['image_url'] as String?;
                  final content = msg['content'] as String?;
                  final timeLabel = _formatTime(msg['created_at']);
                  final createdAt = tryParseApiDateTime(msg['created_at']);

                  var showDateDivider = false;
                  if (createdAt != null) {
                    if (index == 0) {
                      showDateDivider = true;
                    } else {
                      final prev = tryParseApiDateTime(
                        _thread!.messages[index - 1]['created_at'],
                      );
                      showDateDivider = prev == null ||
                          !isSameCalendarDay(createdAt, prev);
                    }
                  }

                  return Column(
                    children: [
                      if (showDateDivider)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  formatKoreanDateDivider(createdAt!),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment:
                              isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isAdmin) ...[
                              _memberAvatar(memberName),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Row(
                                mainAxisAlignment:
                                    isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isAdmin && timeLabel.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                                      child: Text(
                                        timeLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Flexible(
                                    child: _messageBubble(
                                      content: content,
                                      imageUrl: imageUrl,
                                    ),
                                  ),
                                  if (!isAdmin && timeLabel.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        timeLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 8),
                              _adminAvatar(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_pendingImage != null) ...[
            Row(
              children: [
                Text('첨부: ${_pendingImage!.name}', style: const TextStyle(fontSize: 12)),
                IconButton(
                  onPressed: () => setState(() => _pendingImage = null),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.chatBubble,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: TextField(
                    controller: _message,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력해주세요',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: Icon(
                    Icons.send,
                    color: _sending ? AppColors.textSecondary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final s in const [
                ('waiting', '대기중', AppColors.statusWaiting),
                ('in_progress', '진행중', AppColors.statusInProgress),
                ('closed', '답변완료', AppColors.statusCompleted),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: s.$3,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await ref.read(adminApiProvider).updateInquiryStatus(widget.inquiryId, s.$1);
                      await _load();
                    },
                    child: Text(s.$2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
