import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_shell.dart';

class InquiryDetailScreen extends ConsumerStatefulWidget {
  const InquiryDetailScreen({super.key, required this.inquiryId});

  final String inquiryId;

  @override
  ConsumerState<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends ConsumerState<InquiryDetailScreen> {
  InquiryThread? _thread;
  final _message = TextEditingController();
  bool _loading = true;
  bool _sending = false;

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

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(adminApiProvider).sendInquiryMessage(widget.inquiryId, text);
      _message.clear();
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _closeInquiry() async {
    await ref.read(adminApiProvider).updateInquiryStatus(widget.inquiryId, 'closed');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final inquiry = _thread?.inquiry ?? {};
    final member = _thread?.member ?? {};

    return AdminShell(
      title: '문의 상세',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${inquiry['title']} · ${inquiry['status_label']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton(onPressed: _closeInquiry, child: const Text('완료 처리')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${member['name']} · ${member['phone_number']}'),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        itemCount: _thread?.messages.length ?? 0,
                        itemBuilder: (context, index) {
                          final msg = _thread!.messages[index];
                          final isAdmin = msg['is_admin'] == true;
                          return Align(
                            alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: const BoxConstraints(maxWidth: 480),
                              decoration: BoxDecoration(
                                color: isAdmin ? AppColors.secondary : AppColors.inputBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${msg['content']}'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _message,
                          decoration: const InputDecoration(hintText: '답변을 입력하세요'),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _sending ? null : _send,
                        child: Text(_sending ? '전송 중...' : '전송'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
