import 'package:flutter/material.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';

/// CMS-02 / INQ-01-01 공통 회원 정보 헤더
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _InfoTile(label: '이름', value: '${data['name'] ?? '-'}'),
                _InfoTile(label: '닉네임', value: '${data['nickname'] ?? '-'}'),
                _InfoTile(label: '생년월일', value: '${data['birth_date'] ?? '-'}'),
                _InfoTile(label: '휴대폰번호', value: '${data['phone_number'] ?? '-'}'),
                _InfoTile(label: '거주지역', value: '${data['region'] ?? '-'}'),
                _InfoTile(label: '성별', value: '${data['gender'] ?? '-'}'),
                _InfoTile(label: '가입일', value: '${data['joined_at'] ?? '-'}'),
                _InfoTile(label: '신고수', value: '${data['report_count'] ?? 0}'),
                _InfoTile(label: '차단수', value: '${data['block_count'] ?? 0}'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${data['point'] ?? 0}P',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final url in photos.take(4))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, width: 72, height: 72, fit: BoxFit.cover),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
