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
    this.compact = false,
  });

  final Map<String, dynamic> data;
  final List<String> photos;

  /// 문의 상세 등 — 채팅 영역 비중을 위해 헤더를 축소
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pointFmt = NumberFormat('#,###');
    final point = data['point'];
    final pointText = pointFmt.format(point is num ? point : int.tryParse('$point') ?? 0);
    final withdrawn = data['withdrawn'] == true;
    final pad = compact ? 12.0 : 20.0;
    final photoW = compact ? 72.0 : 120.0;
    final photoH = compact ? 68.0 : 112.0;
    final gap = compact ? 10.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                withdrawn ? '회원정보 (탈퇴)' : '회원정보',
                style: TextStyle(
                  fontSize: compact ? 15 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.monetization_on_outlined,
                color: AppColors.primary,
                size: compact ? 18 : 22,
              ),
              const SizedBox(width: 6),
              Text(
                pointText,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) SizedBox(width: compact ? 8 : 12),
                _PhotoSlot(
                  url: withdrawn
                      ? null
                      : (i < photos.length ? photos[i] : null),
                  width: photoW,
                  height: photoH,
                  // NTC-01-01 — 탈퇴 회원 프로필 이미지는 '-' 마스킹
                  maskAsDash: withdrawn,
                ),
              ],
            ],
          ),
          SizedBox(height: gap),
          _InfoGrid(
            compact: compact,
            rows: [
              [
                _GridCell(
                  label: '이름',
                  value: withdrawn ? '*' : '${data['name'] ?? '-'}',
                ),
                _GridCell(
                  label: '닉네임',
                  value: withdrawn ? '*' : '${data['nickname'] ?? '-'}',
                ),
              ],
              [
                _GridCell(
                  label: '생년월일',
                  value: withdrawn ? '-' : '${data['birth_date'] ?? '-'}',
                ),
                _GridCell(
                  label: '휴대폰번호',
                  value: withdrawn ? '-' : '${data['phone_number'] ?? '-'}',
                ),
              ],
              [
                _GridCell(
                  label: '거주지역',
                  value: withdrawn ? '-' : '${data['region'] ?? '-'}',
                ),
                _GridCell(
                  label: '성별',
                  value: withdrawn ? '-' : '${data['gender'] ?? '-'}',
                ),
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
  const _PhotoSlot({
    this.url,
    this.width = 120,
    this.height = 112,
    this.maskAsDash = false,
  });

  final String? url;
  final double width;
  final double height;
  final bool maskAsDash;

  @override
  Widget build(BuildContext context) {
    final resolved = url != null ? resolveAdminMediaUrl(url) : '';
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E4), style: BorderStyle.solid),
      ),
      child: resolved.isNotEmpty
          ? Center(
              child: AdminAspectFitImage.network(
                url: resolved,
                maxWidth: width - 2,
                maxHeight: height - 2,
                borderRadius: 7,
              ),
            )
          : maskAsDash
              ? Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: width < 90 ? 16 : 20,
                    ),
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
  const _InfoGrid({required this.rows, this.compact = false});

  final List<List<_GridCell>> rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in rows) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _LabelValuePair(cell: row[0], compact: compact)),
                Expanded(child: _LabelValuePair(cell: row[1], compact: compact)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LabelValuePair extends StatelessWidget {
  const _LabelValuePair({required this.cell, this.compact = false});

  final _GridCell cell;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padH = compact ? 10.0 : 16.0;
    final padV = compact ? 8.0 : 14.0;
    final fontSize = compact ? 12.0 : 14.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              cell.label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              cell.value,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
