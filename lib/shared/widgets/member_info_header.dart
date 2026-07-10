import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/shared/widgets/admin_aspect_fit_image.dart';
import 'package:randomchat_admin/shared/utils/resolve_admin_media_url.dart';

/// CMS-02 / INQ-01-01 공통 회원 정보 헤더 (Figma 그리드)
class MemberInfoHeader extends StatelessWidget {
  const MemberInfoHeader({
    super.key,
    required this.data,
    this.photos = const [],
  });

  final Map<String, dynamic> data;
  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    final pointFmt = NumberFormat('#,###');
    final point = data['point'];
    final pointText = pointFmt.format(point is num ? point : int.tryParse('$point') ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                '회원정보',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Icon(Icons.monetization_on_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 6),
              Text(
                pointText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                _PhotoSlot(url: i < photos.length ? photos[i] : null),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _InfoGrid(
            rows: [
              [
                _GridCell(label: '이름', value: '${data['name'] ?? '-'}'),
                _GridCell(label: '닉네임', value: '${data['nickname'] ?? '-'}'),
              ],
              [
                _GridCell(label: '생년월일', value: '${data['birth_date'] ?? '-'}'),
                _GridCell(label: '휴대폰번호', value: '${data['phone_number'] ?? '-'}'),
              ],
              [
                _GridCell(label: '거주지역', value: '${data['region'] ?? '-'}'),
                _GridCell(label: '성별', value: '${data['gender'] ?? '-'}'),
              ],
              [
                _GridCell(
                  label: '신고 수',
                  value: _countLabel(data['report_count']),
                ),
                _GridCell(
                  label: '차단 수',
                  value: _countLabel(data['block_count']),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _countLabel(dynamic raw) {
    final n = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    return '${n.toString().padLeft(2, '0')}건';
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final resolved = url != null ? resolveAdminMediaUrl(url) : '';
    return Container(
      width: 120,
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E4), style: BorderStyle.solid),
      ),
      child: resolved.isNotEmpty
          ? Center(
              child: AdminAspectFitImage.network(
                url: resolved,
                maxWidth: 118,
                maxHeight: 110,
                borderRadius: 7,
              ),
            )
          : null,
    );
  }
}

class _GridCell {
  const _GridCell({required this.label, required this.value});

  final String label;
  final String value;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.rows});

  final List<List<_GridCell>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in rows) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _LabelValuePair(cell: row[0])),
                Expanded(child: _LabelValuePair(cell: row[1])),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LabelValuePair extends StatelessWidget {
  const _LabelValuePair({required this.cell});

  final _GridCell cell;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              cell.label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              cell.value,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
