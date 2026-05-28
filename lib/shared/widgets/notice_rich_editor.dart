import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class NoticeRichEditor extends StatefulWidget {
  const NoticeRichEditor({
    super.key,
    required this.controller,
    this.initialHtml,
  });

  final QuillController controller;
  final String? initialHtml;

  static String documentToHtml(QuillController controller) {
    final delta = controller.document.toDelta();
    if (delta.isEmpty) return '';
    final converter = QuillDeltaToHtmlConverter(delta.toJson());
    return converter.convert();
  }

  static bool isEmpty(QuillController controller) {
    return controller.document.toPlainText().trim().isEmpty;
  }

  @override
  State<NoticeRichEditor> createState() => _NoticeRichEditorState();
}

class _NoticeRichEditorState extends State<NoticeRichEditor> {
  @override
  void initState() {
    super.initState();
    final html = widget.initialHtml?.trim();
    if (html != null && html.isNotEmpty) {
      try {
        final delta = HtmlToDelta().convert(html);
        widget.controller.document = Document.fromDelta(delta);
      } catch (_) {
        widget.controller.document = Document()..insert(0, html);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuillSimpleToolbar(
            controller: widget.controller,
            config: const QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              showCodeBlock: false,
              showInlineCode: false,
              showQuote: true,
              showLink: true,
              showListCheck: false,
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 320,
            child: QuillEditor.basic(
              controller: widget.controller,
              config: const QuillEditorConfig(
                placeholder: '내용을 입력하세요',
                padding: EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
