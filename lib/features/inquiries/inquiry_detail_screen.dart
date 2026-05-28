import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_detail_back_bar.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';
import 'package:randomchat_admin/shared/widgets/member_info_header.dart';

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

  static final _timeFmt = DateFormat('hh:mma', 'en_US');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  String _formatTime(dynamic raw) {
    if (raw == null || '$raw'.isEmpty) return '';
    try {
      return _timeFmt.format(DateTime.parse('$raw').toLocal()).toUpperCase();
    } catch (_) {
      return '$raw';
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pendingImage = result.files.first);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final inquiry = _thread?.inquiry ?? {};

    return AdminContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminDetailBackBar(backPath: widget.listPath),
          MemberInfoHeader(data: _thread?.member ?? {}, photos: _photos),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  '${inquiry['title'] ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                Text('${inquiry['status_label'] ?? '-'}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBg.withValues(alpha: 0.35),
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                itemCount: _thread?.messages.length ?? 0,
                itemBuilder: (context, index) {
                  final msg = _thread!.messages[index];
                  final isAdmin = msg['is_admin'] == true;
                  final memberName = '${_thread!.member['name'] ?? '?'}';
                  final imageUrl = msg['image_url'] as String?;
                  final content = msg['content'] as String?;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isAdmin)
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.border,
                            child: Text(memberName.characters.first),
                          ),
                        if (!isAdmin) const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment:
                                isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (content != null && content.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    content,
                                    style: TextStyle(color: isAdmin ? Colors.white : AppColors.text),
                                  ),
                                ),
                              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                if (content != null && content.isNotEmpty) const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(imageUrl, width: 200, fit: BoxFit.cover),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(msg['created_at']),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin) const SizedBox(width: 8),
                        if (isAdmin)
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.support_agent, color: Colors.white, size: 18),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final s in const [
                ('waiting', '대기중'),
                ('in_progress', '진행중'),
                ('closed', '답변완료'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(adminApiProvider).updateInquiryStatus(widget.inquiryId, s.$1);
                      await _load();
                    },
                    child: Text(s.$2),
                  ),
                ),
            ],
          ),
          if (_pendingImage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('첨부: ${_pendingImage!.name}', style: const TextStyle(fontSize: 12)),
                IconButton(
                  onPressed: () => setState(() => _pendingImage = null),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(onPressed: _pickImage, icon: const Icon(Icons.image_outlined)),
              Expanded(
                child: TextField(
                  controller: _message,
                  decoration: const InputDecoration(hintText: '답변을 입력하세요'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(
                onPressed: _sending ? null : _send,
                icon: Icon(Icons.send, color: _sending ? AppColors.textSecondary : AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
